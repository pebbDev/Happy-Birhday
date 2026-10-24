SET local check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.hbd_start_responding (
  p_async_session_id            uuid,
  p_responder_participant_id    uuid,
  p_protected_access_session_id uuid,
  p_continuation_token_hash     bytea,
  p_expected_version            bigint,
  p_idempotency_key             text,
  p_request_hash                bytea
)
  RETURNS jsonb
  LANGUAGE plpgsql
  AS $function$
DECLARE
  v_scope CONSTANT text := 'ASYNC_START_RESPONDING';
  v_existing_hash bytea;
  v_existing_outcome jsonb;
  v_session public.async_session%ROWTYPE;
  v_now timestamptz := transaction_timestamp();
  v_responder_participation_id uuid := gen_random_uuid();
  v_outcome jsonb;
BEGIN
  IF octet_length(p_request_hash) <> 32 OR octet_length(p_continuation_token_hash) <> 32 THEN
    RAISE EXCEPTION 'request/token hash must be 32 bytes';
  END IF;
  IF btrim(p_idempotency_key) = '' THEN RAISE EXCEPTION 'idempotency key must not be blank'; END IF;

  SELECT request_hash, outcome_jsonb INTO v_existing_hash, v_existing_outcome
  FROM public.idempotency_record WHERE command_scope=v_scope AND idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN RAISE EXCEPTION 'idempotency request hash mismatch'; END IF;
    RETURN v_existing_outcome;
  END IF;

  SELECT * INTO v_session FROM public.async_session
  WHERE async_session_id=p_async_session_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'async session not found'; END IF;

  SELECT request_hash, outcome_jsonb INTO v_existing_hash, v_existing_outcome
  FROM public.idempotency_record WHERE command_scope=v_scope AND idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN RAISE EXCEPTION 'idempotency request hash mismatch'; END IF;
    RETURN v_existing_outcome;
  END IF;

  IF v_session.resource_version <> p_expected_version THEN RAISE EXCEPTION 'stale resource version'; END IF;
  IF v_session.state <> 'WAITING' THEN RAISE EXCEPTION 'async session is not WAITING'; END IF;
  IF v_session.response_start_deadline_at IS NULL OR v_now >= v_session.response_start_deadline_at THEN
    RAISE EXCEPTION 'responder start deadline has expired';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.session_participation sp
    WHERE sp.async_session_id=p_async_session_id AND sp.role='INITIATOR'
  ) THEN RAISE EXCEPTION 'initiator participation missing'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.protected_access_session pas
    WHERE pas.protected_access_session_id=p_protected_access_session_id
      AND pas.participant_id=p_responder_participant_id
      AND pas.revoked_at IS NULL AND pas.expires_at > v_now
  ) THEN RAISE EXCEPTION 'protected access session is not valid for responder'; END IF;

  INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
  VALUES (v_responder_participation_id,p_async_session_id,p_responder_participant_id,'RESPONDER');

  INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash,expires_at)
  VALUES (v_responder_participation_id,p_continuation_token_hash,v_now + interval '24 hours');

  UPDATE public.async_session SET
    state='RESPONDING',
    current_editor_session_participation_id=v_responder_participation_id,
    active_editing_access_session_id=p_protected_access_session_id,
    responding_started_at=v_now,
    responding_deadline_at=v_now + interval '24 hours',
    resource_version=resource_version + 1
  WHERE async_session_id=p_async_session_id;

  v_outcome := jsonb_build_object(
    'async_session_id',p_async_session_id,
    'session_participation_id',v_responder_participation_id,
    'state','RESPONDING',
    'resource_version',p_expected_version + 1,
    'responding_started_at',v_now,
    'responding_deadline_at',v_now + interval '24 hours'
  );
  INSERT INTO public.idempotency_record(command_scope,idempotency_key,request_hash,outcome_jsonb)
  VALUES (v_scope,p_idempotency_key,p_request_hash,v_outcome);
  RETURN v_outcome;
END;
$function$;
