CREATE OR REPLACE FUNCTION public.hbd_create_async_session(
  p_initiator_participant_id uuid,
  p_protected_access_session_id uuid,
  p_idempotency_key text,
  p_request_hash bytea
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
  v_scope CONSTANT text := 'ASYNC_CREATE_SESSION';
  v_now timestamptz := transaction_timestamp();
  v_existing_hash bytea;
  v_existing_outcome jsonb;
  v_async_session_id uuid := gen_random_uuid();
  v_session_participation_id uuid := gen_random_uuid();
  v_created_at timestamptz;
  v_outcome jsonb;
BEGIN
  IF octet_length(p_request_hash) <> 32 THEN
    RAISE EXCEPTION 'request hash must be 32 bytes';
  END IF;
  IF btrim(p_idempotency_key) = '' THEN
    RAISE EXCEPTION 'idempotency key must not be blank';
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

  INSERT INTO public.async_session(
    async_session_id,
    state,
    resource_version,
    created_at
  ) VALUES (
    v_async_session_id,
    'INITIATING',
    0,
    v_now
  )
  RETURNING created_at INTO v_created_at;

  INSERT INTO public.session_participation(
    session_participation_id,
    async_session_id,
    participant_id,
    role,
    created_at
  ) VALUES (
    v_session_participation_id,
    v_async_session_id,
    p_initiator_participant_id,
    'INITIATOR',
    v_now
  );

  v_outcome := jsonb_build_object(
    'async_session_id', v_async_session_id,
    'session_participation_id', v_session_participation_id,
    'state', 'INITIATING',
    'resource_version', 0,
    'created_at', v_created_at
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

ALTER FUNCTION public.hbd_create_async_session(uuid, uuid, text, bytea)
  SET search_path = '';

REVOKE ALL ON FUNCTION public.hbd_create_async_session(uuid, uuid, text, bytea)
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.hbd_create_async_session(uuid, uuid, text, bytea)
  TO postgres, service_role;