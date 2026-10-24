CREATE OR REPLACE FUNCTION public.hbd_mark_async_invite_ready(
  p_async_session_id uuid,
  p_initiator_participant_id uuid,
  p_protected_access_session_id uuid,
  p_expected_version bigint,
  p_media_asset_ids uuid[],
  p_idempotency_key text,
  p_request_hash bytea
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
  v_scope CONSTANT text := 'ASYNC_MARK_INVITE_READY';
  v_now timestamptz := transaction_timestamp();
  v_existing_hash bytea;
  v_existing_outcome jsonb;
  v_session public.async_session%ROWTYPE;
  v_initiator_participation_id uuid;
  v_response_id uuid := gen_random_uuid();
  v_distinct_media_count integer;
  v_eligible_media_count integer;
  v_outcome jsonb;
BEGIN
  IF p_request_hash IS NULL OR octet_length(p_request_hash) <> 32 THEN
    RAISE EXCEPTION 'request hash must be 32 bytes';
  END IF;
  IF p_idempotency_key IS NULL OR btrim(p_idempotency_key) = '' THEN
    RAISE EXCEPTION 'idempotency key must not be blank';
  END IF;
  IF p_media_asset_ids IS NULL
     OR cardinality(p_media_asset_ids) <> 4
     OR array_position(p_media_asset_ids, NULL::uuid) IS NOT NULL THEN
    RAISE EXCEPTION 'initiator media asset ids must contain exactly four distinct non-null values';
  END IF;
  SELECT count(DISTINCT media_asset_id)
  INTO v_distinct_media_count
  FROM unnest(p_media_asset_ids) AS media_asset_id;
  IF v_distinct_media_count <> 4 THEN
    RAISE EXCEPTION 'initiator media asset ids must contain exactly four distinct non-null values';
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
  IF v_session.state <> 'INITIATING' THEN
    RAISE EXCEPTION 'async session is not INITIATING';
  END IF;
  IF v_session.invite_ready_at IS NOT NULL
     OR v_session.response_start_deadline_at IS NOT NULL THEN
    RAISE EXCEPTION 'async session invite-ready anchors already exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.protected_access_session pas
    WHERE pas.protected_access_session_id = p_protected_access_session_id
      AND pas.participant_id = p_initiator_participant_id
      AND pas.revoked_at IS NULL
      AND pas.expires_at > v_now
  ) THEN
    RAISE EXCEPTION 'protected access session is not valid for initiator';
  END IF;

  SELECT sp.session_participation_id
  INTO v_initiator_participation_id
  FROM public.session_participation sp
  WHERE sp.async_session_id = p_async_session_id
    AND sp.participant_id = p_initiator_participant_id
    AND sp.role = 'INITIATOR';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'initiator participation invalid';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.async_response ar
    WHERE ar.session_participation_id = v_initiator_participation_id
  ) THEN
    RAISE EXCEPTION 'initiator response already exists';
  END IF;

  SELECT count(*)
  INTO v_eligible_media_count
  FROM public.media_asset ma
  WHERE ma.media_asset_id = ANY(p_media_asset_ids)
    AND ma.uploaded_by_participant_id = p_initiator_participant_id;
  IF v_eligible_media_count <> 4 THEN
    RAISE EXCEPTION 'initiator media assets are not eligible';
  END IF;

  INSERT INTO public.async_response(
    async_response_id,
    session_participation_id,
    created_at,
    updated_at
  ) VALUES (
    v_response_id,
    v_initiator_participation_id,
    v_now,
    v_now
  );

  INSERT INTO public.async_response_media(
    async_response_id,
    cut_position,
    media_asset_id
  )
  SELECT
    v_response_id,
    ordinality::smallint,
    media_asset_id
  FROM unnest(p_media_asset_ids) WITH ORDINALITY AS cuts(media_asset_id, ordinality);

  UPDATE public.async_session
  SET state = 'WAITING',
      invite_ready_at = v_now,
      response_start_deadline_at = v_now + interval '7 days',
      resource_version = resource_version + 1
  WHERE async_session_id = p_async_session_id;

  v_outcome := jsonb_build_object(
    'async_session_id', p_async_session_id,
    'state', 'WAITING',
    'resource_version', p_expected_version + 1,
    'invite_ready_at', v_now,
    'response_start_deadline_at', v_now + interval '7 days'
  );

  INSERT INTO public.idempotency_record(
    command_scope,
    idempotency_key,
    request_hash,
    outcome_jsonb
  ) VALUES (
    v_scope,
    p_idempotency_key,
    p_request_hash,
    v_outcome
  );

  RETURN v_outcome;
END;
$function$;

ALTER FUNCTION public.hbd_mark_async_invite_ready(uuid, uuid, uuid, bigint, uuid[], text, bytea)
  SET search_path = '';
REVOKE ALL ON FUNCTION public.hbd_mark_async_invite_ready(uuid, uuid, uuid, bigint, uuid[], text, bytea)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hbd_mark_async_invite_ready(uuid, uuid, uuid, bigint, uuid[], text, bytea)
  TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.hbd_guard_frozen_initiator_response_media()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') AND EXISTS (
    SELECT 1
    FROM public.async_response ar
    JOIN public.session_participation sp
      ON sp.session_participation_id = ar.session_participation_id
    JOIN public.async_session s
      ON s.async_session_id = sp.async_session_id
    WHERE ar.async_response_id = OLD.async_response_id
      AND sp.role = 'INITIATOR'
      AND s.invite_ready_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'initiator contribution is immutable after invite ready';
  END IF;

  IF TG_OP IN ('INSERT', 'UPDATE') AND EXISTS (
    SELECT 1
    FROM public.async_response ar
    JOIN public.session_participation sp
      ON sp.session_participation_id = ar.session_participation_id
    JOIN public.async_session s
      ON s.async_session_id = sp.async_session_id
    WHERE ar.async_response_id = NEW.async_response_id
      AND sp.role = 'INITIATOR'
      AND s.invite_ready_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'initiator contribution is immutable after invite ready';
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$function$;

ALTER FUNCTION public.hbd_guard_frozen_initiator_response_media()
  SET search_path = '';
REVOKE ALL ON FUNCTION public.hbd_guard_frozen_initiator_response_media()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hbd_guard_frozen_initiator_response_media()
  TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.hbd_guard_frozen_initiator_response()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.async_response ar
    JOIN public.session_participation sp
      ON sp.session_participation_id = ar.session_participation_id
    JOIN public.async_session s
      ON s.async_session_id = sp.async_session_id
    WHERE ar.async_response_id = OLD.async_response_id
      AND sp.role = 'INITIATOR'
      AND s.invite_ready_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'initiator contribution is immutable after invite ready';
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$function$;

ALTER FUNCTION public.hbd_guard_frozen_initiator_response()
  SET search_path = '';
REVOKE ALL ON FUNCTION public.hbd_guard_frozen_initiator_response()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hbd_guard_frozen_initiator_response()
  TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.hbd_guard_frozen_initiator_participation()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF OLD.role = 'INITIATOR' AND EXISTS (
    SELECT 1
    FROM public.async_session s
    WHERE s.async_session_id = OLD.async_session_id
      AND s.invite_ready_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'initiator participation is immutable after invite ready';
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$function$;

ALTER FUNCTION public.hbd_guard_frozen_initiator_participation()
  SET search_path = '';
REVOKE ALL ON FUNCTION public.hbd_guard_frozen_initiator_participation()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hbd_guard_frozen_initiator_participation()
  TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.hbd_guard_invite_ready_anchors()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF OLD.invite_ready_at IS NOT NULL AND (
    NEW.invite_ready_at IS DISTINCT FROM OLD.invite_ready_at
    OR NEW.response_start_deadline_at IS DISTINCT FROM OLD.response_start_deadline_at
  ) THEN
    RAISE EXCEPTION 'invite-ready anchors are immutable';
  END IF;
  RETURN NEW;
END;
$function$;

ALTER FUNCTION public.hbd_guard_invite_ready_anchors()
  SET search_path = '';
REVOKE ALL ON FUNCTION public.hbd_guard_invite_ready_anchors()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hbd_guard_invite_ready_anchors()
  TO postgres, service_role;

CREATE TRIGGER hbd_guard_frozen_initiator_response_media
BEFORE INSERT OR UPDATE OR DELETE ON public.async_response_media
FOR EACH ROW EXECUTE FUNCTION public.hbd_guard_frozen_initiator_response_media();

CREATE TRIGGER hbd_guard_frozen_initiator_response
BEFORE UPDATE OR DELETE ON public.async_response
FOR EACH ROW EXECUTE FUNCTION public.hbd_guard_frozen_initiator_response();

CREATE TRIGGER hbd_guard_frozen_initiator_participation
BEFORE UPDATE OR DELETE ON public.session_participation
FOR EACH ROW EXECUTE FUNCTION public.hbd_guard_frozen_initiator_participation();

CREATE TRIGGER hbd_guard_invite_ready_anchors
BEFORE UPDATE ON public.async_session
FOR EACH ROW EXECUTE FUNCTION public.hbd_guard_invite_ready_anchors();
