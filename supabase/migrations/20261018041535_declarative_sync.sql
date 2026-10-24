SET local check_function_bodies = off;

CREATE TABLE "public"."idempotency_record" (
  "idempotency_record_id" uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "command_scope"         text                     NOT NULL,
  "idempotency_key"       text                     NOT NULL,
  "request_hash"          bytea                    NOT NULL,
  "outcome_jsonb"         jsonb                    NOT NULL,
  "created_at"            timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  CONSTRAINT "chk_idempotency_command_scope_not_blank" CHECK ((btrim(command_scope) <> ''::text)),
  CONSTRAINT "chk_idempotency_key_not_blank" CHECK ((btrim(idempotency_key) <> ''::text)),
  CONSTRAINT "chk_idempotency_outcome_object" CHECK ((jsonb_typeof(outcome_jsonb) = 'object'::text)),
  CONSTRAINT "chk_idempotency_request_hash" CHECK ((octet_length(request_hash) = 32)),
  CONSTRAINT "idempotency_record_pkey" PRIMARY KEY (idempotency_record_id),
  CONSTRAINT "uq_idempotency_scope_key" UNIQUE (command_scope, idempotency_key)
);

ALTER TABLE "public"."idempotency_record"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."idempotency_record" FROM "anon", "authenticated";

CREATE OR REPLACE FUNCTION public.hbd_complete_async_session (
  p_async_session_id            uuid,
  p_responder_participation_id  uuid,
  p_protected_access_session_id uuid,
  p_expected_version            bigint,
  p_idempotency_key             text,
  p_request_hash                bytea
)
  RETURNS jsonb
  LANGUAGE plpgsql
  AS $function$
DECLARE
  v_scope CONSTANT text := 'ASYNC_COMPLETE';
  v_existing_hash bytea;
  v_existing_outcome jsonb;
  v_session public.async_session%ROWTYPE;
  v_now timestamptz := transaction_timestamp();
  v_initiator_participation_id uuid;
  v_initiator_participant_id uuid;
  v_responder_participant_id uuid;
  v_initiator_response_id uuid;
  v_responder_response_id uuid;
  v_count integer;
  v_matched integer;
  v_distinct_media integer;
  v_canonical_memory_id uuid := gen_random_uuid();
  v_outcome jsonb;
BEGIN
  IF octet_length(p_request_hash) <> 32 THEN RAISE EXCEPTION 'request hash must be 32 bytes'; END IF;
  IF btrim(p_idempotency_key) = '' THEN RAISE EXCEPTION 'idempotency key must not be blank'; END IF;

  SELECT request_hash,outcome_jsonb INTO v_existing_hash,v_existing_outcome
  FROM public.idempotency_record WHERE command_scope=v_scope AND idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN RAISE EXCEPTION 'idempotency request hash mismatch'; END IF;
    RETURN v_existing_outcome;
  END IF;

  SELECT * INTO v_session FROM public.async_session
  WHERE async_session_id=p_async_session_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'async session not found'; END IF;

  SELECT request_hash,outcome_jsonb INTO v_existing_hash,v_existing_outcome
  FROM public.idempotency_record WHERE command_scope=v_scope AND idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN RAISE EXCEPTION 'idempotency request hash mismatch'; END IF;
    RETURN v_existing_outcome;
  END IF;

  IF v_session.resource_version <> p_expected_version THEN RAISE EXCEPTION 'stale resource version'; END IF;
  IF v_session.state <> 'RESPONDING' THEN RAISE EXCEPTION 'async session is not RESPONDING'; END IF;
  IF v_session.responding_deadline_at IS NULL OR v_now >= v_session.responding_deadline_at THEN
    RAISE EXCEPTION 'responding window has expired';
  END IF;
  IF v_session.current_editor_session_participation_id IS DISTINCT FROM p_responder_participation_id THEN
    RAISE EXCEPTION 'responder is not current editor';
  END IF;
  IF v_session.active_editing_access_session_id IS DISTINCT FROM p_protected_access_session_id THEN
    RAISE EXCEPTION 'protected access session is not active editor';
  END IF;

  SELECT sp.participant_id INTO v_responder_participant_id
  FROM public.session_participation sp
  WHERE sp.session_participation_id=p_responder_participation_id
    AND sp.async_session_id=p_async_session_id AND sp.role='RESPONDER';
  IF NOT FOUND THEN RAISE EXCEPTION 'responder participation invalid'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.protected_access_session pas
    WHERE pas.protected_access_session_id=p_protected_access_session_id
      AND pas.participant_id=v_responder_participant_id
      AND pas.revoked_at IS NULL AND pas.expires_at > v_now
  ) THEN RAISE EXCEPTION 'responder protected access session invalid'; END IF;

  SELECT sp.session_participation_id,sp.participant_id
  INTO v_initiator_participation_id,v_initiator_participant_id
  FROM public.session_participation sp
  WHERE sp.async_session_id=p_async_session_id AND sp.role='INITIATOR';
  IF NOT FOUND THEN RAISE EXCEPTION 'initiator participation missing'; END IF;

  SELECT async_response_id INTO v_initiator_response_id FROM public.async_response
  WHERE session_participation_id=v_initiator_participation_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'initiator response missing'; END IF;
  SELECT async_response_id INTO v_responder_response_id FROM public.async_response
  WHERE session_participation_id=p_responder_participation_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'responder response missing'; END IF;

  SELECT count(*),count(*) FILTER (WHERE ma.uploaded_by_participant_id=v_initiator_participant_id)
  INTO v_count,v_matched
  FROM public.async_response_media arm JOIN public.media_asset ma ON ma.media_asset_id=arm.media_asset_id
  WHERE arm.async_response_id=v_initiator_response_id;
  IF v_count <> 4 OR v_matched <> 4 THEN RAISE EXCEPTION 'initiator must have exactly four eligible cuts'; END IF;

  SELECT count(*),count(*) FILTER (WHERE ma.uploaded_by_participant_id=v_responder_participant_id)
  INTO v_count,v_matched
  FROM public.async_response_media arm JOIN public.media_asset ma ON ma.media_asset_id=arm.media_asset_id
  WHERE arm.async_response_id=v_responder_response_id;
  IF v_count <> 4 OR v_matched <> 4 THEN RAISE EXCEPTION 'responder must have exactly four eligible cuts'; END IF;

  SELECT count(DISTINCT media_asset_id) INTO v_distinct_media
  FROM public.async_response_media
  WHERE async_response_id IN (v_initiator_response_id,v_responder_response_id);
  IF v_distinct_media <> 8 THEN RAISE EXCEPTION 'canonical completion requires eight distinct media assets'; END IF;
  IF EXISTS (SELECT 1 FROM public.canonical_memory WHERE async_session_id=p_async_session_id) THEN
    RAISE EXCEPTION 'canonical memory already exists';
  END IF;

  INSERT INTO public.canonical_memory(canonical_memory_id,async_session_id,created_at)
  VALUES (v_canonical_memory_id,p_async_session_id,v_now);

  INSERT INTO public.canonical_memory_media(canonical_memory_id,session_participation_id,cut_position,media_asset_id)
  SELECT v_canonical_memory_id,v_initiator_participation_id,cut_position,media_asset_id
  FROM public.async_response_media WHERE async_response_id=v_initiator_response_id
  UNION ALL
  SELECT v_canonical_memory_id,p_responder_participation_id,cut_position,media_asset_id
  FROM public.async_response_media WHERE async_response_id=v_responder_response_id;

  IF (SELECT count(*) FROM public.canonical_memory_media WHERE canonical_memory_id=v_canonical_memory_id) <> 8 THEN
    RAISE EXCEPTION 'canonical memory materialization did not produce eight rows';
  END IF;

  UPDATE public.async_session SET
    state='COMPLETED',completed_at=v_now,
    current_editor_session_participation_id=NULL,
    active_editing_access_session_id=NULL,
    resource_version=resource_version + 1
  WHERE async_session_id=p_async_session_id;

  v_outcome := jsonb_build_object(
    'async_session_id',p_async_session_id,
    'canonical_memory_id',v_canonical_memory_id,
    'state','COMPLETED',
    'resource_version',p_expected_version + 1,
    'completed_at',v_now
  );
  INSERT INTO public.idempotency_record(command_scope,idempotency_key,request_hash,outcome_jsonb)
  VALUES (v_scope,p_idempotency_key,p_request_hash,v_outcome);
  RETURN v_outcome;
END;
$function$;

REVOKE ALL ON FUNCTION "public"."hbd_complete_async_session"(uuid, uuid, uuid, bigint, text, bytea) FROM PUBLIC, "anon", "authenticated";

CREATE OR REPLACE FUNCTION public.hbd_release_claim (
  p_async_session_id            uuid,
  p_responder_participation_id  uuid,
  p_protected_access_session_id uuid,
  p_expected_version            bigint,
  p_idempotency_key             text,
  p_request_hash                bytea
)
  RETURNS jsonb
  LANGUAGE plpgsql
  AS $function$
DECLARE
  v_scope CONSTANT text := 'ASYNC_RELEASE_CLAIM';
  v_existing_hash bytea;
  v_existing_outcome jsonb;
  v_session public.async_session%ROWTYPE;
  v_now timestamptz := transaction_timestamp();
  v_confirmed_count integer;
  v_outcome jsonb;
BEGIN
  IF octet_length(p_request_hash) <> 32 THEN RAISE EXCEPTION 'request hash must be 32 bytes'; END IF;
  IF btrim(p_idempotency_key) = '' THEN RAISE EXCEPTION 'idempotency key must not be blank'; END IF;

  SELECT request_hash,outcome_jsonb INTO v_existing_hash,v_existing_outcome
  FROM public.idempotency_record WHERE command_scope=v_scope AND idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN RAISE EXCEPTION 'idempotency request hash mismatch'; END IF;
    RETURN v_existing_outcome;
  END IF;

  SELECT * INTO v_session FROM public.async_session
  WHERE async_session_id=p_async_session_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'async session not found'; END IF;

  SELECT request_hash,outcome_jsonb INTO v_existing_hash,v_existing_outcome
  FROM public.idempotency_record WHERE command_scope=v_scope AND idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN RAISE EXCEPTION 'idempotency request hash mismatch'; END IF;
    RETURN v_existing_outcome;
  END IF;

  IF v_session.resource_version <> p_expected_version THEN RAISE EXCEPTION 'stale resource version'; END IF;
  IF v_session.state <> 'RESPONDING' THEN RAISE EXCEPTION 'async session is not RESPONDING'; END IF;
  IF v_session.current_editor_session_participation_id IS DISTINCT FROM p_responder_participation_id THEN
    RAISE EXCEPTION 'responder is not current editor';
  END IF;
  IF v_session.active_editing_access_session_id IS DISTINCT FROM p_protected_access_session_id THEN
    RAISE EXCEPTION 'protected access session is not active editor';
  END IF;
  IF v_session.response_start_deadline_at IS NULL OR v_now >= v_session.response_start_deadline_at THEN
    RAISE EXCEPTION 'original responder start window has expired';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.session_participation sp
    JOIN public.protected_access_session pas ON pas.participant_id=sp.participant_id
    WHERE sp.session_participation_id=p_responder_participation_id
      AND sp.async_session_id=p_async_session_id AND sp.role='RESPONDER'
      AND pas.protected_access_session_id=p_protected_access_session_id
      AND pas.revoked_at IS NULL AND pas.expires_at > v_now
  ) THEN RAISE EXCEPTION 'responder editing authority invalid'; END IF;

  SELECT count(*) INTO v_confirmed_count
  FROM public.async_response ar
  JOIN public.async_response_media arm ON arm.async_response_id=ar.async_response_id
  WHERE ar.session_participation_id=p_responder_participation_id;
  IF v_confirmed_count > 0 THEN RAISE EXCEPTION 'responder claim cannot be released after first confirmed cut'; END IF;

  UPDATE public.async_session SET
    state='WAITING',
    current_editor_session_participation_id=NULL,
    active_editing_access_session_id=NULL,
    responding_started_at=NULL,
    responding_deadline_at=NULL,
    resource_version=resource_version + 1
  WHERE async_session_id=p_async_session_id;

  DELETE FROM public.session_participation
  WHERE session_participation_id=p_responder_participation_id
    AND async_session_id=p_async_session_id AND role='RESPONDER';

  v_outcome := jsonb_build_object(
    'async_session_id',p_async_session_id,
    'state','WAITING',
    'resource_version',p_expected_version + 1
  );
  INSERT INTO public.idempotency_record(command_scope,idempotency_key,request_hash,outcome_jsonb)
  VALUES (v_scope,p_idempotency_key,p_request_hash,v_outcome);
  RETURN v_outcome;
END;
$function$;

REVOKE ALL ON FUNCTION "public"."hbd_release_claim"(uuid, uuid, uuid, bigint, text, bytea) FROM PUBLIC, "anon", "authenticated";

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

REVOKE ALL ON FUNCTION "public"."hbd_start_responding"(uuid, uuid, uuid, bytea, bigint, text, bytea) FROM PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."hbd_complete_async_session"(uuid, uuid, uuid, bigint, text, bytea) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."hbd_complete_async_session"(uuid, uuid, uuid, bigint, text, bytea) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."hbd_complete_async_session"(uuid, uuid, uuid, bigint, text, bytea) TO "service_role";

REVOKE ALL ON FUNCTION "public"."hbd_release_claim"(uuid, uuid, uuid, bigint, text, bytea) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."hbd_release_claim"(uuid, uuid, uuid, bigint, text, bytea) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."hbd_release_claim"(uuid, uuid, uuid, bigint, text, bytea) TO "service_role";

REVOKE ALL ON FUNCTION "public"."hbd_start_responding"(uuid, uuid, uuid, bytea, bigint, text, bytea) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."hbd_start_responding"(uuid, uuid, uuid, bytea, bigint, text, bytea) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."hbd_start_responding"(uuid, uuid, uuid, bytea, bigint, text, bytea) TO "service_role";

REVOKE ALL ON TABLE "public"."idempotency_record" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."idempotency_record" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."idempotency_record" TO "service_role";
