BEGIN;

INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-0000000000a4','Initiator A4'),
('00000000-0000-0000-0000-0000000000b4','Responder B4');

INSERT INTO public.protected_access_session(
  protected_access_session_id,participant_id,session_token_hash,expires_at
) VALUES (
  '10000000-0000-0000-0000-0000000000b4',
  '00000000-0000-0000-0000-0000000000b4',
  decode(repeat('61',32),'hex'), transaction_timestamp() + interval '2 days'
);

INSERT INTO public.async_session(async_session_id,state,resource_version)
VALUES ('20000000-0000-0000-0000-000000000004','INITIATING',10);

INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-0000000000a4','20000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-0000000000a4','INITIATOR'),
('30000000-0000-0000-0000-0000000000b4','20000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-0000000000b4','RESPONDER');

INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES
('40000000-0000-0000-0000-0000000000a4','30000000-0000-0000-0000-0000000000a4'),
('40000000-0000-0000-0000-0000000000b4','30000000-0000-0000-0000-0000000000b4');

INSERT INTO public.media_asset(media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type) VALUES
('50000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000a4','TENCENT_COS','session5/a1.jpg',decode(repeat('71',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-0000000000a2','00000000-0000-0000-0000-0000000000a4','TENCENT_COS','session5/a2.jpg',decode(repeat('72',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-0000000000a3','00000000-0000-0000-0000-0000000000a4','TENCENT_COS','session5/a3.jpg',decode(repeat('73',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-0000000000a4','00000000-0000-0000-0000-0000000000a4','TENCENT_COS','session5/a4.jpg',decode(repeat('74',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-0000000000b1','00000000-0000-0000-0000-0000000000b4','TENCENT_COS','session5/b1c.jpg',decode(repeat('81',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-0000000000b2','00000000-0000-0000-0000-0000000000b4','TENCENT_COS','session5/b2.jpg',decode(repeat('82',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-0000000000b3','00000000-0000-0000-0000-0000000000b4','TENCENT_COS','session5/b3.jpg',decode(repeat('83',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-0000000000b4','00000000-0000-0000-0000-0000000000b4','TENCENT_COS','session5/b4.jpg',decode(repeat('84',32),'hex'),'image/jpeg');

INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES
('40000000-0000-0000-0000-0000000000a4',1,'50000000-0000-0000-0000-0000000000a1'),
('40000000-0000-0000-0000-0000000000a4',2,'50000000-0000-0000-0000-0000000000a2'),
('40000000-0000-0000-0000-0000000000a4',3,'50000000-0000-0000-0000-0000000000a3'),
('40000000-0000-0000-0000-0000000000a4',4,'50000000-0000-0000-0000-0000000000a4'),
('40000000-0000-0000-0000-0000000000b4',1,'50000000-0000-0000-0000-0000000000b1'),
('40000000-0000-0000-0000-0000000000b4',2,'50000000-0000-0000-0000-0000000000b2'),
('40000000-0000-0000-0000-0000000000b4',3,'50000000-0000-0000-0000-0000000000b3'),
('40000000-0000-0000-0000-0000000000b4',4,'50000000-0000-0000-0000-0000000000b4');

UPDATE public.async_session SET
  state='RESPONDING',
  invite_ready_at=transaction_timestamp()-interval '1 day',
  response_start_deadline_at=transaction_timestamp()+interval '6 days',
  responding_started_at=transaction_timestamp()-interval '1 hour',
  responding_deadline_at=transaction_timestamp()+interval '23 hours',
  current_editor_session_participation_id='30000000-0000-0000-0000-0000000000b4',
  active_editing_access_session_id='10000000-0000-0000-0000-0000000000b4'
WHERE async_session_id='20000000-0000-0000-0000-000000000004';

DO $$
DECLARE
  outcome jsonb;
  replay jsonb;
  cm_id uuid;
  media_count integer;
BEGIN
  outcome := public.hbd_complete_async_session(
    '20000000-0000-0000-0000-000000000004',
    '30000000-0000-0000-0000-0000000000b4',
    '10000000-0000-0000-0000-0000000000b4',
    10,'complete-1',decode(repeat('91',32),'hex')
  );
  cm_id := (outcome->>'canonical_memory_id')::uuid;

  IF outcome->>'state' <> 'COMPLETED' THEN RAISE EXCEPTION 'completion outcome not COMPLETED'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.async_session
    WHERE async_session_id='20000000-0000-0000-0000-000000000004'
      AND state='COMPLETED' AND resource_version=11
      AND completed_at IS NOT NULL
      AND current_editor_session_participation_id IS NULL
      AND active_editing_access_session_id IS NULL
  ) THEN RAISE EXCEPTION 'completed session mutation invalid'; END IF;

  SELECT count(*) INTO media_count FROM public.canonical_memory_media WHERE canonical_memory_id=cm_id;
  IF media_count <> 8 THEN RAISE EXCEPTION 'canonical media expected 8 got %', media_count; END IF;
  IF (SELECT count(DISTINCT cut_position) FROM public.canonical_memory_media WHERE canonical_memory_id=cm_id) <> 4 THEN
    RAISE EXCEPTION 'canonical cut positions not exactly 1..4';
  END IF;

  replay := public.hbd_complete_async_session(
    '20000000-0000-0000-0000-000000000004',
    '30000000-0000-0000-0000-0000000000b4',
    '10000000-0000-0000-0000-0000000000b4',
    10,'complete-1',decode(repeat('91',32),'hex')
  );
  IF replay <> outcome THEN RAISE EXCEPTION 'completion replay changed outcome'; END IF;
  IF (SELECT count(*) FROM public.canonical_memory WHERE async_session_id='20000000-0000-0000-0000-000000000004') <> 1 THEN
    RAISE EXCEPTION 'replay created duplicate CanonicalMemory';
  END IF;
END $$;

-- Incomplete B-side must fail.
INSERT INTO public.async_session(async_session_id,state,resource_version)
VALUES ('20000000-0000-0000-0000-000000000005','INITIATING',3);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-0000000000a5','20000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-0000000000a4','INITIATOR'),
('30000000-0000-0000-0000-0000000000b5','20000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-0000000000b4','RESPONDER');
INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES
('40000000-0000-0000-0000-0000000000a5','30000000-0000-0000-0000-0000000000a5'),
('40000000-0000-0000-0000-0000000000b5','30000000-0000-0000-0000-0000000000b5');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id)
SELECT '40000000-0000-0000-0000-0000000000a5'::uuid, cut_position, media_asset_id
FROM public.async_response_media WHERE async_response_id='40000000-0000-0000-0000-0000000000a4' AND cut_position BETWEEN 1 AND 4;
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id)
SELECT '40000000-0000-0000-0000-0000000000b5'::uuid, cut_position, media_asset_id
FROM public.async_response_media WHERE async_response_id='40000000-0000-0000-0000-0000000000b4' AND cut_position BETWEEN 1 AND 3;

UPDATE public.async_session SET
  state='RESPONDING',
  invite_ready_at=transaction_timestamp()-interval '1 day',
  response_start_deadline_at=transaction_timestamp()+interval '6 days',
  responding_started_at=transaction_timestamp()-interval '1 hour',
  responding_deadline_at=transaction_timestamp()+interval '23 hours',
  current_editor_session_participation_id='30000000-0000-0000-0000-0000000000b5',
  active_editing_access_session_id='10000000-0000-0000-0000-0000000000b4'
WHERE async_session_id='20000000-0000-0000-0000-000000000005';

DO $$
BEGIN
  BEGIN
    PERFORM public.hbd_complete_async_session(
      '20000000-0000-0000-0000-000000000005',
      '30000000-0000-0000-0000-0000000000b5',
      '10000000-0000-0000-0000-0000000000b4',3,'complete-incomplete',decode(repeat('92',32),'hex')
    );
    RAISE EXCEPTION 'incomplete completion unexpectedly accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'incomplete completion unexpectedly accepted' THEN RAISE; END IF;
  END;
END $$;

ROLLBACK;
SELECT 'complete_async_session_command_test PASS' AS result;
