BEGIN;

INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-0000000000a2','Initiator A2'),
('00000000-0000-0000-0000-0000000000b2','Responder B2');

INSERT INTO public.protected_access_session(
  protected_access_session_id,participant_id,session_token_hash,expires_at
) VALUES (
  '10000000-0000-0000-0000-0000000000b2',
  '00000000-0000-0000-0000-0000000000b2',
  decode(repeat('31',32),'hex'), transaction_timestamp() + interval '2 days'
);

INSERT INTO public.async_session(
  async_session_id,state,resource_version,invite_ready_at,response_start_deadline_at,
  responding_started_at,responding_deadline_at
) VALUES (
  '20000000-0000-0000-0000-000000000002','RESPONDING',5,
  transaction_timestamp() - interval '2 hours',transaction_timestamp()+interval '5 days',
  transaction_timestamp() - interval '1 hour',transaction_timestamp()+interval '23 hours'
);

INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-0000000000a2','20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000a2','INITIATOR'),
('30000000-0000-0000-0000-0000000000b2','20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000b2','RESPONDER');

UPDATE public.async_session SET
  current_editor_session_participation_id='30000000-0000-0000-0000-0000000000b2',
  active_editing_access_session_id='10000000-0000-0000-0000-0000000000b2'
WHERE async_session_id='20000000-0000-0000-0000-000000000002';

INSERT INTO public.async_response(async_response_id,session_participation_id)
VALUES ('40000000-0000-0000-0000-0000000000b2','30000000-0000-0000-0000-0000000000b2');
INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash)
VALUES ('30000000-0000-0000-0000-0000000000b2',decode(repeat('32',32),'hex'));

DO $$
DECLARE
  outcome jsonb;
  replay jsonb;
BEGIN
  outcome := public.hbd_release_claim(
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-0000000000b2',
    '10000000-0000-0000-0000-0000000000b2',
    5,'release-1',decode(repeat('41',32),'hex')
  );

  IF outcome->>'state' <> 'WAITING' THEN RAISE EXCEPTION 'release outcome not WAITING'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.async_session
    WHERE async_session_id='20000000-0000-0000-0000-000000000002'
      AND state='WAITING' AND resource_version=6
      AND current_editor_session_participation_id IS NULL
      AND active_editing_access_session_id IS NULL
      AND responding_started_at IS NULL AND responding_deadline_at IS NULL
      AND response_start_deadline_at IS NOT NULL
  ) THEN RAISE EXCEPTION 'release session mutation invalid'; END IF;

  IF EXISTS (SELECT 1 FROM public.session_participation WHERE session_participation_id='30000000-0000-0000-0000-0000000000b2') THEN
    RAISE EXCEPTION 'provisional responder participation not deleted';
  END IF;
  IF EXISTS (SELECT 1 FROM public.async_response WHERE async_response_id='40000000-0000-0000-0000-0000000000b2') THEN
    RAISE EXCEPTION 'responder response not cascaded';
  END IF;

  replay := public.hbd_release_claim(
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-0000000000b2',
    '10000000-0000-0000-0000-0000000000b2',
    5,'release-1',decode(repeat('41',32),'hex')
  );
  IF replay <> outcome THEN RAISE EXCEPTION 'release replay changed outcome'; END IF;
END $$;

-- Separate responder with B1 confirmed: release must fail.
INSERT INTO public.async_session(
  async_session_id,state,resource_version,invite_ready_at,response_start_deadline_at,
  responding_started_at,responding_deadline_at
) VALUES (
  '20000000-0000-0000-0000-000000000003','RESPONDING',2,
  transaction_timestamp()-interval '1 hour',transaction_timestamp()+interval '6 days',
  transaction_timestamp()-interval '10 minutes',transaction_timestamp()+interval '23 hours 50 minutes'
);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-0000000000a3','20000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-0000000000a2','INITIATOR'),
('30000000-0000-0000-0000-0000000000b3','20000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-0000000000b2','RESPONDER');
UPDATE public.async_session SET current_editor_session_participation_id='30000000-0000-0000-0000-0000000000b3', active_editing_access_session_id='10000000-0000-0000-0000-0000000000b2'
WHERE async_session_id='20000000-0000-0000-0000-000000000003';
INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES
('40000000-0000-0000-0000-0000000000b3','30000000-0000-0000-0000-0000000000b3');
INSERT INTO public.media_asset(media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type) VALUES
('50000000-0000-0000-0000-0000000000b3','00000000-0000-0000-0000-0000000000b2','TENCENT_COS','session5/b1.jpg',decode(repeat('51',32),'hex'),'image/jpeg');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES
('40000000-0000-0000-0000-0000000000b3',1,'50000000-0000-0000-0000-0000000000b3');

DO $$
BEGIN
  BEGIN
    PERFORM public.hbd_release_claim(
      '20000000-0000-0000-0000-000000000003',
      '30000000-0000-0000-0000-0000000000b3',
      '10000000-0000-0000-0000-0000000000b2',2,'release-after-b1',decode(repeat('42',32),'hex')
    );
    RAISE EXCEPTION 'release after B1 unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'release after B1 unexpectedly accepted' THEN RAISE; END IF;
  END;
END $$;

ROLLBACK;
SELECT 'release_claim_command_test PASS' AS result;
