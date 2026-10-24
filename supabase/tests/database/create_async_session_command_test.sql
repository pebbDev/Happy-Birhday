BEGIN;

INSERT INTO public.participant(participant_id,display_name)
VALUES ('00000000-0000-0000-0000-0000000000e1','Create Initiator');

INSERT INTO public.protected_access_session(
  protected_access_session_id, participant_id, session_token_hash, expires_at
) VALUES (
  '10000000-0000-0000-0000-0000000000e1',
  '00000000-0000-0000-0000-0000000000e1',
  decode(repeat('e1',32),'hex'),
  transaction_timestamp() + interval '2 days'
);

DO $$
DECLARE
  first_outcome jsonb;
  replay_outcome jsonb;
  replay_after_revoke jsonb;
  session_id uuid;
  participation_id uuid;
  session_count integer;
  participation_count integer;
  idem_count integer;
BEGIN
  first_outcome := public.hbd_create_async_session(
    '00000000-0000-0000-0000-0000000000e1',
    '10000000-0000-0000-0000-0000000000e1',
    'create-session-1',
    decode(repeat('aa',32),'hex')
  );

  IF first_outcome->>'state' <> 'INITIATING' THEN
    RAISE EXCEPTION 'create outcome not INITIATING: %', first_outcome;
  END IF;
  IF (first_outcome->>'resource_version')::bigint <> 0 THEN
    RAISE EXCEPTION 'create outcome resource_version must be 0: %', first_outcome;
  END IF;
  IF first_outcome->>'created_at' IS NULL THEN
    RAISE EXCEPTION 'create outcome created_at missing: %', first_outcome;
  END IF;

  session_id := (first_outcome->>'async_session_id')::uuid;
  participation_id := (first_outcome->>'session_participation_id')::uuid;

  IF NOT EXISTS (
    SELECT 1 FROM public.async_session s
    WHERE s.async_session_id=session_id
      AND s.state='INITIATING'
      AND s.resource_version=0
      AND s.invite_ready_at IS NULL
      AND s.response_start_deadline_at IS NULL
      AND s.responding_started_at IS NULL
      AND s.responding_deadline_at IS NULL
      AND s.current_editor_session_participation_id IS NULL
      AND s.active_editing_access_session_id IS NULL
      AND s.completed_at IS NULL
      AND s.expired_at IS NULL
      AND s.created_at=(first_outcome->>'created_at')::timestamptz
  ) THEN
    RAISE EXCEPTION 'persisted INITIATING session invariants invalid';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.session_participation sp
    WHERE sp.session_participation_id=participation_id
      AND sp.async_session_id=session_id
      AND sp.participant_id='00000000-0000-0000-0000-0000000000e1'
      AND sp.role='INITIATOR'
  ) THEN
    RAISE EXCEPTION 'trusted initiator participation missing';
  END IF;

  replay_outcome := public.hbd_create_async_session(
    '00000000-0000-0000-0000-0000000000e1',
    '10000000-0000-0000-0000-0000000000e1',
    'create-session-1',
    decode(repeat('aa',32),'hex')
  );
  IF replay_outcome <> first_outcome THEN
    RAISE EXCEPTION 'exact replay changed outcome';
  END IF;

  SELECT count(*) INTO session_count
  FROM public.async_session WHERE async_session_id=session_id;
  SELECT count(*) INTO participation_count
  FROM public.session_participation WHERE async_session_id=session_id;
  IF session_count <> 1 OR participation_count <> 1 THEN
    RAISE EXCEPTION 'exact replay duplicated canonical rows';
  END IF;

  BEGIN
    PERFORM public.hbd_create_async_session(
      '00000000-0000-0000-0000-0000000000e1',
      '10000000-0000-0000-0000-0000000000e1',
      'create-session-1',
      decode(repeat('bb',32),'hex')
    );
    RAISE EXCEPTION 'idempotency hash mismatch unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'idempotency hash mismatch unexpectedly accepted' THEN RAISE; END IF;
    IF SQLERRM <> 'idempotency request hash mismatch' THEN
      RAISE EXCEPTION 'unexpected mismatch error: %', SQLERRM;
    END IF;
  END;

  UPDATE public.protected_access_session
  SET revoked_at=transaction_timestamp()
  WHERE protected_access_session_id='10000000-0000-0000-0000-0000000000e1';

  replay_after_revoke := public.hbd_create_async_session(
    '00000000-0000-0000-0000-0000000000e1',
    '10000000-0000-0000-0000-0000000000e1',
    'create-session-1',
    decode(repeat('aa',32),'hex')
  );
  IF replay_after_revoke <> first_outcome THEN
    RAISE EXCEPTION 'durable replay must survive later access-session revocation';
  END IF;

  BEGIN
    PERFORM public.hbd_create_async_session(
      '00000000-0000-0000-0000-0000000000e1',
      '10000000-0000-0000-0000-0000000000e1',
      'create-session-revoked',
      decode(repeat('cc',32),'hex')
    );
    RAISE EXCEPTION 'revoked access session unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'revoked access session unexpectedly accepted' THEN RAISE; END IF;
  END;

  SELECT count(*) INTO idem_count FROM public.idempotency_record
  WHERE command_scope='ASYNC_CREATE_SESSION' AND idempotency_key='create-session-revoked';
  IF idem_count <> 0 THEN RAISE EXCEPTION 'rejected revoked mutation left idempotency state'; END IF;

  SELECT count(*) INTO session_count FROM public.async_session
  WHERE async_session_id <> session_id;
  IF session_count <> 0 THEN RAISE EXCEPTION 'rejected revoked mutation left extra async session'; END IF;
END $$;

INSERT INTO public.protected_access_session(
  protected_access_session_id, participant_id, session_token_hash, created_at, expires_at
) VALUES (
  '10000000-0000-0000-0000-0000000000e2',
  '00000000-0000-0000-0000-0000000000e1',
  decode(repeat('e2',32),'hex'),
  transaction_timestamp() - interval '2 days',
  transaction_timestamp() - interval '1 day'
);

DO $$
DECLARE
  session_count integer;
  participation_count integer;
  idem_count integer;
BEGIN
  SELECT count(*) INTO session_count FROM public.async_session;
  SELECT count(*) INTO participation_count FROM public.session_participation;
  BEGIN
    PERFORM public.hbd_create_async_session(
      '00000000-0000-0000-0000-0000000000e1',
      '10000000-0000-0000-0000-0000000000e2',
      'create-session-expired',
      decode(repeat('dd',32),'hex')
    );
    RAISE EXCEPTION 'expired access session unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'expired access session unexpectedly accepted' THEN RAISE; END IF;
  END;
  IF (SELECT count(*) FROM public.async_session) <> session_count THEN
    RAISE EXCEPTION 'rejected expired mutation left async session state';
  END IF;
  IF (SELECT count(*) FROM public.session_participation) <> participation_count THEN
    RAISE EXCEPTION 'rejected expired mutation left participation state';
  END IF;
  SELECT count(*) INTO idem_count FROM public.idempotency_record
  WHERE command_scope='ASYNC_CREATE_SESSION' AND idempotency_key='create-session-expired';
  IF idem_count <> 0 THEN RAISE EXCEPTION 'rejected expired mutation left idempotency state'; END IF;
END $$;

ROLLBACK;
SELECT 'create_async_session_command_test PASS' AS result;