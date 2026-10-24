BEGIN;

INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-00000000ac01','Frozen Initiator'),
('00000000-0000-0000-0000-00000000bc01','Release Responder');
INSERT INTO public.protected_access_session(protected_access_session_id,participant_id,session_token_hash,expires_at) VALUES
('10000000-0000-0000-0000-00000000ac01','00000000-0000-0000-0000-00000000ac01',decode(repeat('c1',32),'hex'),transaction_timestamp()+interval '2 days'),
('10000000-0000-0000-0000-00000000bc01','00000000-0000-0000-0000-00000000bc01',decode(repeat('c2',32),'hex'),transaction_timestamp()+interval '2 days');
INSERT INTO public.media_asset(media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type) VALUES
('50000000-0000-0000-0000-00000000ac01','00000000-0000-0000-0000-00000000ac01','TENCENT_COS','freeze/a1.jpg',decode(repeat('41',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000ac02','00000000-0000-0000-0000-00000000ac01','TENCENT_COS','freeze/a2.jpg',decode(repeat('42',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000ac03','00000000-0000-0000-0000-00000000ac01','TENCENT_COS','freeze/a3.jpg',decode(repeat('43',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000ac04','00000000-0000-0000-0000-00000000ac01','TENCENT_COS','freeze/a4.jpg',decode(repeat('44',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000ac05','00000000-0000-0000-0000-00000000ac01','TENCENT_COS','freeze/a5.jpg',decode(repeat('45',32),'hex'),'image/jpeg');
INSERT INTO public.async_session(async_session_id,state,resource_version)
VALUES ('20000000-0000-0000-0000-000000000201','INITIATING',0);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-000000000201','20000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-00000000ac01','INITIATOR');

SELECT public.hbd_mark_async_invite_ready(
  '20000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-00000000ac01','10000000-0000-0000-0000-00000000ac01',0,
  ARRAY['50000000-0000-0000-0000-00000000ac01'::uuid,'50000000-0000-0000-0000-00000000ac02'::uuid,'50000000-0000-0000-0000-00000000ac03'::uuid,'50000000-0000-0000-0000-00000000ac04'::uuid],
  'freeze-invite',decode(repeat('46',32),'hex')
);

DO $$
DECLARE
  response_id uuid;
  original_invite timestamptz;
  original_deadline timestamptz;
BEGIN
  SELECT ar.async_response_id INTO response_id
  FROM public.async_response ar WHERE ar.session_participation_id='30000000-0000-0000-0000-000000000201';
  SELECT invite_ready_at,response_start_deadline_at INTO original_invite,original_deadline
  FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000201';

  BEGIN
    INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id)
    VALUES (response_id,1,'50000000-0000-0000-0000-00000000ac05');
    RAISE EXCEPTION 'frozen initiator media insert unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='frozen initiator media insert unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator contribution is immutable after invite ready' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected insert guard error: %',SQLERRM; END IF;
  END;

  BEGIN
    UPDATE public.async_response_media SET media_asset_id='50000000-0000-0000-0000-00000000ac05'
    WHERE async_response_id=response_id AND cut_position=2;
    RAISE EXCEPTION 'frozen initiator media update unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='frozen initiator media update unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator contribution is immutable after invite ready' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected update guard error: %',SQLERRM; END IF;
  END;

  BEGIN
    DELETE FROM public.async_response_media WHERE async_response_id=response_id AND cut_position=4;
    RAISE EXCEPTION 'frozen initiator media delete unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='frozen initiator media delete unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator contribution is immutable after invite ready' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected delete guard error: %',SQLERRM; END IF;
  END;

  BEGIN
    UPDATE public.async_response SET updated_at=transaction_timestamp()+interval '1 second' WHERE async_response_id=response_id;
    RAISE EXCEPTION 'frozen initiator response update unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='frozen initiator response update unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator contribution is immutable after invite ready' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected response update guard error: %',SQLERRM; END IF;
  END;

  BEGIN
    DELETE FROM public.async_response WHERE async_response_id=response_id;
    RAISE EXCEPTION 'frozen initiator response delete unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='frozen initiator response delete unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator contribution is immutable after invite ready' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected response delete guard error: %',SQLERRM; END IF;
  END;

  BEGIN
    UPDATE public.session_participation SET participant_id='00000000-0000-0000-0000-00000000bc01'
    WHERE session_participation_id='30000000-0000-0000-0000-000000000201';
    RAISE EXCEPTION 'frozen initiator participation update unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='frozen initiator participation update unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator participation is immutable after invite ready' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected participation update guard error: %',SQLERRM; END IF;
  END;

  BEGIN
    DELETE FROM public.session_participation WHERE session_participation_id='30000000-0000-0000-0000-000000000201';
    RAISE EXCEPTION 'frozen initiator participation delete unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='frozen initiator participation delete unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator participation is immutable after invite ready' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected participation delete guard error: %',SQLERRM; END IF;
  END;

  BEGIN
    UPDATE public.async_session SET invite_ready_at=NULL WHERE async_session_id='20000000-0000-0000-0000-000000000201';
    RAISE EXCEPTION 'invite_ready_at clear unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='invite_ready_at clear unexpectedly accepted' THEN RAISE; END IF;
    IF position('invite-ready anchors are immutable' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected invite anchor guard error: %',SQLERRM; END IF;
  END;

  BEGIN
    UPDATE public.async_session SET response_start_deadline_at=response_start_deadline_at+interval '1 hour'
    WHERE async_session_id='20000000-0000-0000-0000-000000000201';
    RAISE EXCEPTION 'response_start_deadline_at change unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='response_start_deadline_at change unexpectedly accepted' THEN RAISE; END IF;
    IF position('invite-ready anchors are immutable' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected deadline anchor guard error: %',SQLERRM; END IF;
  END;

  IF NOT EXISTS (
    SELECT 1 FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000201'
      AND invite_ready_at=original_invite AND response_start_deadline_at=original_deadline
  ) THEN RAISE EXCEPTION 'guard attempts changed canonical anchors'; END IF;
END $$;

DO $$
DECLARE
  start_outcome jsonb;
  release_outcome jsonb;
  responder_id uuid;
  responder_response_id uuid := '40000000-0000-0000-0000-0000000002b1';
  original_invite timestamptz;
  original_deadline timestamptz;
  a_response_id uuid;
BEGIN
  SELECT invite_ready_at,response_start_deadline_at INTO original_invite,original_deadline
  FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000201';
  SELECT async_response_id INTO a_response_id FROM public.async_response
  WHERE session_participation_id='30000000-0000-0000-0000-000000000201';

  start_outcome := public.hbd_start_responding(
    '20000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-00000000bc01','10000000-0000-0000-0000-00000000bc01',
    decode(repeat('47',32),'hex'),1,'freeze-start',decode(repeat('48',32),'hex')
  );
  responder_id := (start_outcome->>'session_participation_id')::uuid;
  INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES (responder_response_id,responder_id);

  release_outcome := public.hbd_release_claim(
    '20000000-0000-0000-0000-000000000201',responder_id,'10000000-0000-0000-0000-00000000bc01',2,
    'freeze-release',decode(repeat('49',32),'hex')
  );
  IF release_outcome->>'state' <> 'WAITING' OR (release_outcome->>'resource_version')::bigint <> 3 THEN
    RAISE EXCEPTION 'release regression outcome invalid: %',release_outcome;
  END IF;
  IF EXISTS (SELECT 1 FROM public.session_participation WHERE session_participation_id=responder_id) THEN
    RAISE EXCEPTION 'release regression left responder participation';
  END IF;
  IF EXISTS (SELECT 1 FROM public.async_response WHERE async_response_id=responder_response_id) THEN
    RAISE EXCEPTION 'release regression left responder response';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000201'
      AND state='WAITING' AND resource_version=3
      AND invite_ready_at=original_invite AND response_start_deadline_at=original_deadline
      AND current_editor_session_participation_id IS NULL AND active_editing_access_session_id IS NULL
      AND responding_started_at IS NULL AND responding_deadline_at IS NULL
  ) THEN RAISE EXCEPTION 'release regression changed anchors or failed to clear responder state'; END IF;
  IF (SELECT count(*) FROM public.async_response_media WHERE async_response_id=a_response_id) <> 4 THEN
    RAISE EXCEPTION 'release regression changed frozen A-side';
  END IF;
END $$;

ROLLBACK;
SELECT 'initiator_freeze_guards_test PASS' AS result;
