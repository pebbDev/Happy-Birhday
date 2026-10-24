CREATE OR REPLACE FUNCTION public.hbd_save_async_response_cut(
  p_async_session_id uuid,
  p_responder_participation_id uuid,
  p_protected_access_session_id uuid,
  p_cut_position smallint,
  p_media_asset_id uuid,
  p_expected_version bigint,
  p_idempotency_key text,
  p_request_hash bytea
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
  v_scope CONSTANT text := 'ASYNC_SAVE_RESPONSE_CUT';
  v_now timestamptz := transaction_timestamp();
  v_existing_hash bytea;
  v_existing_outcome jsonb;
  v_session public.async_session%ROWTYPE;
  v_responder_participant_id uuid;
  v_response_id uuid;
  v_positions smallint[] := ARRAY[]::smallint[];
  v_expected_positions smallint[] := ARRAY[]::smallint[];
  v_existing_media_id uuid;
  v_response_media jsonb;
  v_outcome jsonb;
  v_next_version bigint;
BEGIN
  IF p_request_hash IS NULL OR octet_length(p_request_hash) <> 32 THEN
    RAISE EXCEPTION 'request hash must be 32 bytes';
  END IF;
  IF p_idempotency_key IS NULL OR btrim(p_idempotency_key) = '' THEN
    RAISE EXCEPTION 'idempotency key must not be blank';
  END IF;
  IF p_cut_position IS NULL OR p_cut_position < 1 OR p_cut_position > 4 THEN
    RAISE EXCEPTION 'cut position must be between 1 and 4';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(v_scope || ':' || p_idempotency_key, 0)
  );

  SELECT request_hash, outcome_jsonb
  INTO v_existing_hash, v_existing_outcome
  FROM public.idempotency_record
  WHERE command_scope = v_scope
    AND idempotency_key = p_idempotency_key;

  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN
      RAISE EXCEPTION 'idempotency request hash mismatch';
    END IF;
    RETURN v_existing_outcome;
  END IF;

  SELECT *
  INTO v_session
  FROM public.async_session
  WHERE async_session_id = p_async_session_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'async session not found';
  END IF;

  SELECT request_hash, outcome_jsonb
  INTO v_existing_hash, v_existing_outcome
  FROM public.idempotency_record
  WHERE command_scope = v_scope
    AND idempotency_key = p_idempotency_key;

  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN
      RAISE EXCEPTION 'idempotency request hash mismatch';
    END IF;
    RETURN v_existing_outcome;
  END IF;

  IF v_session.resource_version <> p_expected_version THEN
    RAISE EXCEPTION 'stale resource version';
  END IF;
  IF v_session.state <> 'RESPONDING' THEN
    RAISE EXCEPTION 'async session is not responding';
  END IF;
  IF v_session.responding_deadline_at IS NULL OR v_now >= v_session.responding_deadline_at THEN
    RAISE EXCEPTION 'responding window has expired';
  END IF;

  SELECT sp.participant_id
  INTO v_responder_participant_id
  FROM public.session_participation sp
  WHERE sp.session_participation_id = p_responder_participation_id
    AND sp.async_session_id = p_async_session_id
    AND sp.role = 'RESPONDER';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'responder participation invalid';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.protected_access_session pas
    WHERE pas.protected_access_session_id = p_protected_access_session_id
      AND pas.participant_id = v_responder_participant_id
      AND pas.revoked_at IS NULL
      AND pas.expires_at > v_now
  ) THEN
    RAISE EXCEPTION 'protected access session is not valid for responder';
  END IF;

  IF v_session.current_editor_session_participation_id IS DISTINCT FROM p_responder_participation_id THEN
    RAISE EXCEPTION 'responder is not current editor';
  END IF;
  IF v_session.active_editing_access_session_id IS DISTINCT FROM p_protected_access_session_id THEN
    RAISE EXCEPTION 'protected access session is not active editor';
  END IF;

  SELECT ar.async_response_id
  INTO v_response_id
  FROM public.async_response ar
  WHERE ar.session_participation_id = p_responder_participation_id;

  IF FOUND THEN
    SELECT coalesce(array_agg(arm.cut_position ORDER BY arm.cut_position), ARRAY[]::smallint[])
    INTO v_positions
    FROM public.async_response_media arm
    WHERE arm.async_response_id = v_response_id;
  ELSE
    v_response_id := NULL;
    v_positions := ARRAY[]::smallint[];
  END IF;

  SELECT ARRAY(
    SELECT generate_series(1, cardinality(v_positions))::smallint
  ) INTO v_expected_positions;

  IF v_positions IS DISTINCT FROM v_expected_positions THEN
    RAISE EXCEPTION 'responder response media prefix invariant violated';
  END IF;

  IF NOT (
    p_cut_position = ANY(v_positions)
    OR p_cut_position = cardinality(v_positions) + 1
  ) THEN
    RAISE EXCEPTION 'responder response sequence conflict';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.media_asset ma
    WHERE ma.media_asset_id = p_media_asset_id
      AND ma.uploaded_by_participant_id = v_responder_participant_id
      AND lower(ma.mime_type) LIKE 'image/%'
  ) THEN
    RAISE EXCEPTION 'responder media asset is not eligible';
  END IF;

  IF v_response_id IS NOT NULL AND EXISTS (
    SELECT 1
    FROM public.async_response_media arm
    WHERE arm.async_response_id = v_response_id
      AND arm.media_asset_id = p_media_asset_id
      AND arm.cut_position <> p_cut_position
  ) THEN
    RAISE EXCEPTION 'responder media asset already used in another cut';
  END IF;

  IF v_response_id IS NOT NULL THEN
    SELECT arm.media_asset_id
    INTO v_existing_media_id
    FROM public.async_response_media arm
    WHERE arm.async_response_id = v_response_id
      AND arm.cut_position = p_cut_position;
  END IF;

  IF v_existing_media_id IS NOT NULL AND v_existing_media_id = p_media_asset_id THEN
    SELECT coalesce(
      jsonb_agg(
        jsonb_build_object(
          'cut_position', arm.cut_position,
          'media_asset_id', arm.media_asset_id
        ) ORDER BY arm.cut_position
      ),
      '[]'::jsonb
    )
    INTO v_response_media
    FROM public.async_response_media arm
    WHERE arm.async_response_id = v_response_id;

    v_outcome := jsonb_build_object(
      'async_session_id', p_async_session_id,
      'responder_participation_id', p_responder_participation_id,
      'state', 'RESPONDING',
      'resource_version', p_expected_version,
      'responding_started_at', v_session.responding_started_at,
      'responding_deadline_at', v_session.responding_deadline_at,
      'saved_at', v_now,
      'response_media', v_response_media
    );

    INSERT INTO public.idempotency_record(
      command_scope,idempotency_key,request_hash,outcome_jsonb
    ) VALUES (
      v_scope,p_idempotency_key,p_request_hash,v_outcome
    );
    RETURN v_outcome;
  END IF;

  IF v_response_id IS NULL THEN
    v_response_id := gen_random_uuid();
    INSERT INTO public.async_response(
      async_response_id,session_participation_id,created_at,updated_at
    ) VALUES (
      v_response_id,p_responder_participation_id,v_now,v_now
    );
  END IF;

  INSERT INTO public.async_response_media(
    async_response_id,cut_position,media_asset_id
  ) VALUES (
    v_response_id,p_cut_position,p_media_asset_id
  )
  ON CONFLICT (async_response_id,cut_position)
  DO UPDATE SET media_asset_id = EXCLUDED.media_asset_id;

  UPDATE public.async_response
  SET updated_at = v_now
  WHERE async_response_id = v_response_id;

  UPDATE public.async_session
  SET resource_version = resource_version + 1
  WHERE async_session_id = p_async_session_id;

  v_next_version := p_expected_version + 1;

  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'cut_position', arm.cut_position,
        'media_asset_id', arm.media_asset_id
      ) ORDER BY arm.cut_position
    ),
    '[]'::jsonb
  )
  INTO v_response_media
  FROM public.async_response_media arm
  WHERE arm.async_response_id = v_response_id;

  v_outcome := jsonb_build_object(
    'async_session_id', p_async_session_id,
    'responder_participation_id', p_responder_participation_id,
    'state', 'RESPONDING',
    'resource_version', v_next_version,
    'responding_started_at', v_session.responding_started_at,
    'responding_deadline_at', v_session.responding_deadline_at,
    'saved_at', v_now,
    'response_media', v_response_media
  );

  INSERT INTO public.idempotency_record(
    command_scope,idempotency_key,request_hash,outcome_jsonb
  ) VALUES (
    v_scope,p_idempotency_key,p_request_hash,v_outcome
  );

  RETURN v_outcome;
END;
$function$;

ALTER FUNCTION public.hbd_save_async_response_cut(uuid, uuid, uuid, smallint, uuid, bigint, text, bytea)
  SET search_path = '';
REVOKE ALL ON FUNCTION public.hbd_save_async_response_cut(uuid, uuid, uuid, smallint, uuid, bigint, text, bytea)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hbd_save_async_response_cut(uuid, uuid, uuid, smallint, uuid, bigint, text, bytea)
  TO postgres, service_role;
