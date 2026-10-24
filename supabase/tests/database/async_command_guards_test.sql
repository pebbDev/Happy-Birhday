BEGIN;

INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-0000000000c1','Initiator C'),
('00000000-0000-0000-0000-0000000000d1','Responder D');
INSERT INTO public.protected_access_session(protected_access_session_id,participant_id,session_token_hash,expires_at)
VALUES ('10000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000d1',decode(repeat('a1',32),'hex'),transaction_timestamp()+interval '2 days');

-- WAITING without initiator must not accept responder claim.
INSERT INTO public.async_session(async_session_id,state,resource_version,invite_ready_at,response_start_deadline_at)
VALUES ('20000000-0000-0000-0000-0000000000c1','WAITING',0,transaction_timestamp()-interval '1 hour',transaction_timestamp()+interval '6 days');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_start_responding(
      '20000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-0000000000d1','10000000-0000-0000-0000-0000000000d1',
      decode(repeat('a2',32),'hex'),0,'guard-no-initiator',decode(repeat('a3',32),'hex'));
    RAISE EXCEPTION 'start without initiator unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='start without initiator unexpectedly accepted' THEN RAISE; END IF;
  END;
END $$;

-- Valid initiator exists, but stale expected_version must fail.
INSERT INTO public.async_session(async_session_id,state,resource_version,invite_ready_at,response_start_deadline_at)
VALUES ('20000000-0000-0000-0000-0000000000c2','WAITING',3,transaction_timestamp()-interval '1 hour',transaction_timestamp()+interval '6 days');
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-0000000000c2','20000000-0000-0000-0000-0000000000c2','00000000-0000-0000-0000-0000000000c1','INITIATOR');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_start_responding(
      '20000000-0000-0000-0000-0000000000c2','00000000-0000-0000-0000-0000000000d1','10000000-0000-0000-0000-0000000000d1',
      decode(repeat('a4',32),'hex'),2,'guard-stale',decode(repeat('a5',32),'hex'));
    RAISE EXCEPTION 'stale version unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='stale version unexpectedly accepted' THEN RAISE; END IF;
  END;
END $$;

-- Expired original 7-day start window must fail.
INSERT INTO public.async_session(async_session_id,state,resource_version,invite_ready_at,response_start_deadline_at)
VALUES ('20000000-0000-0000-0000-0000000000c3','WAITING',0,transaction_timestamp()-interval '8 days',transaction_timestamp()-interval '1 day');
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-0000000000c3','20000000-0000-0000-0000-0000000000c3','00000000-0000-0000-0000-0000000000c1','INITIATOR');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_start_responding(
      '20000000-0000-0000-0000-0000000000c3','00000000-0000-0000-0000-0000000000d1','10000000-0000-0000-0000-0000000000d1',
      decode(repeat('a6',32),'hex'),0,'guard-expired',decode(repeat('a7',32),'hex'));
    RAISE EXCEPTION 'expired start window unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='expired start window unexpectedly accepted' THEN RAISE; END IF;
  END;
END $$;

ROLLBACK;
SELECT 'async_command_guards_test PASS' AS result;
