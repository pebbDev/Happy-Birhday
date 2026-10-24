BEGIN;

INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-0000000000a1','Initiator A'),
('00000000-0000-0000-0000-0000000000b1','Responder B');

INSERT INTO public.protected_access_session(
  protected_access_session_id,participant_id,session_token_hash,expires_at
) VALUES (
  '10000000-0000-0000-0000-0000000000b1',
  '00000000-0000-0000-0000-0000000000b1',
  decode(repeat('11',32),'hex'), transaction_timestamp() + interval '2 days'
);

INSERT INTO public.async_session(
  async_session_id,state,resource_version,invite_ready_at,response_start_deadline_at
) VALUES (
  '20000000-0000-0000-0000-000000000001','WAITING',0,
  transaction_timestamp() - interval '1 hour',
  transaction_timestamp() + interval '6 days'
);

INSERT INTO public.session_participation(
  session_participation_id,async_session_id,participant_id,role
) VALUES (
  '30000000-0000-0000-0000-0000000000a1',
  '20000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-0000000000a1','INITIATOR'
);

DO $$
DECLARE
  first_outcome jsonb;
  replay_outcome jsonb;
  responder_id uuid;
  version_now bigint;
  responder_count integer;
BEGIN
  first_outcome := public.hbd_start_responding(
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000b1',
    '10000000-0000-0000-0000-0000000000b1',
    decode(repeat('22',32),'hex'),
    0,
    'start-responding-1',
    decode(repeat('aa',32),'hex')
  );

  responder_id := (first_outcome->>'session_participation_id')::uuid;
  IF first_outcome->>'state' <> 'RESPONDING' THEN
    RAISE EXCEPTION 'start outcome not RESPONDING: %', first_outcome;
  END IF;

  SELECT resource_version INTO version_now
  FROM public.async_session
  WHERE async_session_id='20000000-0000-0000-0000-000000000001';
  IF version_now <> 1 THEN RAISE EXCEPTION 'version expected 1 got %', version_now; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.async_session
    WHERE async_session_id='20000000-0000-0000-0000-000000000001'
      AND state='RESPONDING'
      AND current_editor_session_participation_id=responder_id
      AND active_editing_access_session_id='10000000-0000-0000-0000-0000000000b1'
      AND responding_started_at IS NOT NULL
      AND responding_deadline_at = responding_started_at + interval '24 hours'
  ) THEN RAISE EXCEPTION 'session start mutation invalid'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.responder_continuation_authority
    WHERE session_participation_id=responder_id
      AND token_hash=decode(repeat('22',32),'hex')
  ) THEN RAISE EXCEPTION 'continuation authority missing'; END IF;

  replay_outcome := public.hbd_start_responding(
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000b1',
    '10000000-0000-0000-0000-0000000000b1',
    decode(repeat('22',32),'hex'),0,'start-responding-1',decode(repeat('aa',32),'hex')
  );
  IF replay_outcome <> first_outcome THEN RAISE EXCEPTION 'idempotent replay changed outcome'; END IF;

  SELECT count(*) INTO responder_count FROM public.session_participation
  WHERE async_session_id='20000000-0000-0000-0000-000000000001' AND role='RESPONDER';
  IF responder_count <> 1 THEN RAISE EXCEPTION 'replay created duplicate responder'; END IF;

  BEGIN
    PERFORM public.hbd_start_responding(
      '20000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000b1',
      '10000000-0000-0000-0000-0000000000b1',
      decode(repeat('22',32),'hex'),0,'start-responding-1',decode(repeat('bb',32),'hex')
    );
    RAISE EXCEPTION 'idempotency hash mismatch unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'idempotency hash mismatch unexpectedly accepted' THEN RAISE; END IF;
  END;
END $$;

ROLLBACK;
SELECT 'start_responding_command_test PASS' AS result;
