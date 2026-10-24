CREATE OR REPLACE FUNCTION public.hbd_continue_responding(
  p_async_session_id uuid,
  p_responder_participant_id uuid,
  p_protected_access_session_id uuid,
  p_continuation_token_hash bytea
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $function$
DECLARE
  v_now timestamptz := transaction_timestamp();
  v_session public.async_session%ROWTYPE;
  v_responder_participation_id uuid;
  v_response_id uuid;
  v_positions smallint[] := ARRAY[]::smallint[];
  v_expected_positions smallint[] := ARRAY[]::smallint[];
  v_response_media jsonb := '[]'::jsonb;
BEGIN
  IF p_continuation_token_hash IS NULL OR octet_length(p_continuation_token_hash) <> 32 THEN
    RAISE EXCEPTION 'continuation token hash must be 32 bytes';
  END IF;

  SELECT *
  INTO v_session
  FROM public.async_session
  WHERE async_session_id = p_async_session_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'async session not found';
  END IF;

  IF v_session.state <> 'RESPONDING' THEN
    RAISE EXCEPTION 'async session is not responding';
  END IF;
  IF v_session.responding_deadline_at IS NULL OR v_now >= v_session.responding_deadline_at THEN
    RAISE EXCEPTION 'responding window has expired';
  END IF;

  SELECT sp.session_participation_id
  INTO v_responder_participation_id
  FROM public.session_participation sp
  WHERE sp.async_session_id = p_async_session_id
    AND sp.participant_id = p_responder_participant_id
    AND sp.role = 'RESPONDER';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'continuation authority invalid';
  END IF;

  IF v_session.current_editor_session_participation_id IS DISTINCT FROM v_responder_participation_id THEN
    RAISE EXCEPTION 'current editor responder participation invalid';
  END IF;
  IF v_session.active_editing_access_session_id IS NULL THEN
    RAISE EXCEPTION 'active editing access session is missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.protected_access_session pas
    WHERE pas.protected_access_session_id = p_protected_access_session_id
      AND pas.participant_id = p_responder_participant_id
      AND pas.revoked_at IS NULL
      AND pas.expires_at > v_now
  ) THEN
    RAISE EXCEPTION 'continuation authority invalid';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.responder_continuation_authority rca
    WHERE rca.session_participation_id = v_responder_participation_id
      AND rca.token_hash = p_continuation_token_hash
      AND rca.revoked_at IS NULL
      AND (rca.expires_at IS NULL OR rca.expires_at > v_now)
  ) THEN
    RAISE EXCEPTION 'continuation authority invalid';
  END IF;

  SELECT ar.async_response_id
  INTO v_response_id
  FROM public.async_response ar
  WHERE ar.session_participation_id = v_responder_participation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'continuation requires durable responder progress';
  END IF;

  SELECT coalesce(array_agg(arm.cut_position ORDER BY arm.cut_position), ARRAY[]::smallint[])
  INTO v_positions
  FROM public.async_response_media arm
  WHERE arm.async_response_id = v_response_id;

  IF cardinality(v_positions) = 0 THEN
    RAISE EXCEPTION 'continuation requires durable responder progress';
  END IF;

  SELECT ARRAY(
    SELECT generate_series(1, cardinality(v_positions))::smallint
  ) INTO v_expected_positions;
  IF v_positions IS DISTINCT FROM v_expected_positions OR cardinality(v_positions) > 4 THEN
    RAISE EXCEPTION 'responder response media prefix invariant violated';
  END IF;

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

  RETURN jsonb_build_object(
    'async_session_id', p_async_session_id,
    'responder_participation_id', v_responder_participation_id,
    'state', 'RESPONDING',
    'resource_version', v_session.resource_version,
    'responding_started_at', v_session.responding_started_at,
    'responding_deadline_at', v_session.responding_deadline_at,
    'resolved_at', v_now,
    'caller_is_active_editor', v_session.active_editing_access_session_id = p_protected_access_session_id,
    'response_media', v_response_media
  );
END;
$function$;

ALTER FUNCTION public.hbd_continue_responding(uuid, uuid, uuid, bytea)
  SET search_path = '';
REVOKE ALL ON FUNCTION public.hbd_continue_responding(uuid, uuid, uuid, bytea)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hbd_continue_responding(uuid, uuid, uuid, bytea)
  TO postgres, service_role;
