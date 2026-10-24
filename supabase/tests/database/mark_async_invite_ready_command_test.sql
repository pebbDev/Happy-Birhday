BEGIN;

INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-00000000aa01','Invite Initiator A'),
('00000000-0000-0000-0000-00000000bb01','Invite Other Participant');

INSERT INTO public.protected_access_session(
  protected_access_session_id,participant_id,session_token_hash,created_at,expires_at,revoked_at
) VALUES
('10000000-0000-0000-0000-00000000aa01','00000000-0000-0000-0000-00000000aa01',decode(repeat('a1',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',NULL),
('10000000-0000-0000-0000-00000000aa02','00000000-0000-0000-0000-00000000aa01',decode(repeat('a2',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',transaction_timestamp()),
('10000000-0000-0000-0000-00000000aa03','00000000-0000-0000-0000-00000000aa01',decode(repeat('a3',32),'hex'),transaction_timestamp()-interval '2 hours',transaction_timestamp()-interval '1 hour',NULL),
('10000000-0000-0000-0000-00000000bb01','00000000-0000-0000-0000-00000000bb01',decode(repeat('b1',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',NULL);

INSERT INTO public.media_asset(
  media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type
) VALUES
('50000000-0000-0000-0000-00000000aa01','00000000-0000-0000-0000-00000000aa01','TENCENT_COS','invite-ready/a1.jpg',decode(repeat('11',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa02','00000000-0000-0000-0000-00000000aa01','TENCENT_COS','invite-ready/a2.jpg',decode(repeat('12',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa03','00000000-0000-0000-0000-00000000aa01','TENCENT_COS','invite-ready/a3.jpg',decode(repeat('13',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa04','00000000-0000-0000-0000-00000000aa01','TENCENT_COS','invite-ready/a4.jpg',decode(repeat('14',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa05','00000000-0000-0000-0000-00000000aa01','TENCENT_COS','invite-ready/a5.jpg',decode(repeat('15',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb01','00000000-0000-0000-0000-00000000bb01','TENCENT_COS','invite-ready/other.jpg',decode(repeat('21',32),'hex'),'image/jpeg');

INSERT INTO public.async_session(async_session_id,state,resource_version)
VALUES ('20000000-0000-0000-0000-000000000101','INITIATING',0);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-000000000101','20000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-00000000aa01','INITIATOR');

DO $$
DECLARE
  first_outcome jsonb;
  replay_outcome jsonb;
  response_id uuid;
  response_count integer;
  media_count integer;
  responder_count integer;
  positions smallint[];
  media_ids uuid[];
  v_invite timestamptz;
  v_deadline timestamptz;
BEGIN
  first_outcome := public.hbd_mark_async_invite_ready(
    '20000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-00000000aa01',
    '10000000-0000-0000-0000-00000000aa01',
    0,
    ARRAY[
      '50000000-0000-0000-0000-00000000aa01'::uuid,
      '50000000-0000-0000-0000-00000000aa02'::uuid,
      '50000000-0000-0000-0000-00000000aa03'::uuid,
      '50000000-0000-0000-0000-00000000aa04'::uuid
    ],
    'invite-ready-1',decode(repeat('31',32),'hex')
  );

  IF first_outcome->>'state' <> 'WAITING' THEN RAISE EXCEPTION 'invite-ready outcome not WAITING: %', first_outcome; END IF;
  IF (first_outcome->>'resource_version')::bigint <> 1 THEN RAISE EXCEPTION 'invite-ready version must be 1: %', first_outcome; END IF;
  IF (SELECT count(*) FROM jsonb_object_keys(first_outcome)) <> 5
     OR NOT (first_outcome ?& ARRAY['async_session_id','state','resource_version','invite_ready_at','response_start_deadline_at']) THEN
    RAISE EXCEPTION 'invite-ready outcome shape invalid: %', first_outcome;
  END IF;

  SELECT invite_ready_at,response_start_deadline_at INTO v_invite,v_deadline
  FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000101';
  IF v_invite IS NULL OR v_deadline IS NULL OR v_deadline-v_invite <> interval '7 days' THEN
    RAISE EXCEPTION 'invite-ready canonical anchors invalid';
  END IF;
  IF (first_outcome->>'invite_ready_at')::timestamptz <> v_invite
     OR (first_outcome->>'response_start_deadline_at')::timestamptz <> v_deadline THEN
    RAISE EXCEPTION 'outcome anchors differ from persisted canonical values';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.async_session
    WHERE async_session_id='20000000-0000-0000-0000-000000000101'
      AND state='WAITING' AND resource_version=1
      AND current_editor_session_participation_id IS NULL
      AND active_editing_access_session_id IS NULL
      AND responding_started_at IS NULL AND responding_deadline_at IS NULL
      AND completed_at IS NULL AND expired_at IS NULL
  ) THEN RAISE EXCEPTION 'invite-ready session mutation invalid'; END IF;

  SELECT count(*) INTO response_count
  FROM public.async_response WHERE session_participation_id='30000000-0000-0000-0000-000000000101';
  IF response_count <> 1 THEN RAISE EXCEPTION 'expected exactly one initiator response, got %', response_count; END IF;
  SELECT async_response_id INTO response_id
  FROM public.async_response WHERE session_participation_id='30000000-0000-0000-0000-000000000101'
  LIMIT 1;

  SELECT count(*),array_agg(cut_position ORDER BY cut_position),array_agg(media_asset_id ORDER BY cut_position)
  INTO media_count,positions,media_ids
  FROM public.async_response_media WHERE async_response_id=response_id;
  IF media_count <> 4 OR positions <> ARRAY[1,2,3,4]::smallint[] OR media_ids <> ARRAY[
      '50000000-0000-0000-0000-00000000aa01'::uuid,
      '50000000-0000-0000-0000-00000000aa02'::uuid,
      '50000000-0000-0000-0000-00000000aa03'::uuid,
      '50000000-0000-0000-0000-00000000aa04'::uuid
    ] THEN
    RAISE EXCEPTION 'initiator media materialization invalid';
  END IF;
  SELECT count(*) INTO responder_count FROM public.session_participation
  WHERE async_session_id='20000000-0000-0000-0000-000000000101' AND role='RESPONDER';
  IF responder_count <> 0 THEN RAISE EXCEPTION 'invite-ready created responder participation'; END IF;

  replay_outcome := public.hbd_mark_async_invite_ready(
    '20000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-00000000aa01',
    '10000000-0000-0000-0000-00000000aa01',0,
    ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],
    'invite-ready-1',decode(repeat('31',32),'hex')
  );
  IF replay_outcome <> first_outcome THEN RAISE EXCEPTION 'invite-ready exact replay changed outcome'; END IF;
  SELECT count(*) INTO response_count FROM public.async_response WHERE session_participation_id='30000000-0000-0000-0000-000000000101';
  SELECT count(*) INTO media_count FROM public.async_response_media WHERE async_response_id=response_id;
  IF response_count <> 1 OR media_count <> 4 THEN RAISE EXCEPTION 'exact replay duplicated canonical rows'; END IF;

  BEGIN
    PERFORM public.hbd_mark_async_invite_ready(
      '20000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-00000000aa01',
      '10000000-0000-0000-0000-00000000aa01',0,
      ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa05'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],
      'invite-ready-1',decode(repeat('32',32),'hex')
    );
    RAISE EXCEPTION 'invite-ready hash mismatch unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='invite-ready hash mismatch unexpectedly accepted' THEN RAISE; END IF;
    IF position('idempotency request hash mismatch' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected mismatch error: %',SQLERRM; END IF;
  END;
END $$;

INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES ('20000000-0000-0000-0000-000000000102','INITIATING',2);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-000000000102','20000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-00000000aa01','INITIATOR');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_mark_async_invite_ready('20000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-00000000aa01','10000000-0000-0000-0000-00000000aa01',1,
      ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],
      'invite-stale',decode(repeat('33',32),'hex'));
    RAISE EXCEPTION 'stale invite unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='stale invite unexpectedly accepted' THEN RAISE; END IF;
    IF position('stale resource version' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected stale error: %',SQLERRM; END IF;
  END;
END $$;

DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_mark_async_invite_ready('20000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-00000000aa01','10000000-0000-0000-0000-00000000aa01',1,
      ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],
      'invite-state-conflict',decode(repeat('34',32),'hex'));
    RAISE EXCEPTION 'non-INITIATING invite unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='non-INITIATING invite unexpectedly accepted' THEN RAISE; END IF;
    IF position('async session is not INITIATING' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected state error: %',SQLERRM; END IF;
  END;
END $$;

INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES ('20000000-0000-0000-0000-000000000103','INITIATING',0);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-000000000103','20000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-00000000aa01','INITIATOR');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_mark_async_invite_ready('20000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-00000000bb01','10000000-0000-0000-0000-00000000bb01',0,
      ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],
      'invite-wrong-participant',decode(repeat('35',32),'hex'));
    RAISE EXCEPTION 'non-initiator invite unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='non-initiator invite unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator participation invalid' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected initiator authority error: %',SQLERRM; END IF;
  END;
END $$;

DO $$ DECLARE sid uuid; key text; BEGIN
  FOREACH sid IN ARRAY ARRAY['10000000-0000-0000-0000-00000000aa02'::uuid,'10000000-0000-0000-0000-00000000aa03'::uuid] LOOP
    key := 'invite-bad-access-' || sid::text;
    BEGIN
      PERFORM public.hbd_mark_async_invite_ready('20000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-00000000aa01',sid,0,
        ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],
        key,decode(repeat('36',32),'hex'));
      RAISE EXCEPTION 'invalid protected session unexpectedly accepted';
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM='invalid protected session unexpectedly accepted' THEN RAISE; END IF;
      IF position('protected access session is not valid for initiator' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected protected-session error: %',SQLERRM; END IF;
    END;
  END LOOP;
END $$;

INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES ('20000000-0000-0000-0000-000000000104','INITIATING',0);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-000000000104','20000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-00000000aa01','INITIATOR');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_mark_async_invite_ready('20000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-00000000aa01','10000000-0000-0000-0000-00000000aa01',0,
      ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'50000000-0000-0000-0000-00000000bb01'::uuid],
      'invite-wrong-media-owner',decode(repeat('37',32),'hex'));
    RAISE EXCEPTION 'foreign-owned media unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='foreign-owned media unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator media assets are not eligible' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected media authority error: %',SQLERRM; END IF;
  END;
  IF EXISTS (SELECT 1 FROM public.async_response WHERE session_participation_id='30000000-0000-0000-0000-000000000104') THEN RAISE EXCEPTION 'media authorization failure left partial response'; END IF;
END $$;

INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES ('20000000-0000-0000-0000-000000000105','INITIATING',0);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-000000000105','20000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-00000000aa01','INITIATOR');
DO $$ DECLARE ids uuid[]; label text; BEGIN
  FOR ids,label IN
    SELECT * FROM (VALUES
      (ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid],'three'),
      (ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid,'50000000-0000-0000-0000-00000000aa05'::uuid],'five'),
      (ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],'duplicate'),
      (ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,NULL::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],'null')
    ) AS v(ids,label)
  LOOP
    BEGIN
      PERFORM public.hbd_mark_async_invite_ready('20000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-00000000aa01','10000000-0000-0000-0000-00000000aa01',0,ids,
        'invite-invalid-array-'||label,decode(repeat('38',32),'hex'));
      RAISE EXCEPTION 'invalid media array unexpectedly accepted: %',label;
    EXCEPTION WHEN OTHERS THEN
      IF position('invalid media array unexpectedly accepted' in SQLERRM)>0 THEN RAISE; END IF;
      IF position('initiator media asset ids must contain exactly four distinct non-null values' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected array error for %: %',label,SQLERRM; END IF;
    END;
  END LOOP;
  IF EXISTS (SELECT 1 FROM public.async_response WHERE session_participation_id='30000000-0000-0000-0000-000000000105') THEN RAISE EXCEPTION 'invalid array left partial response'; END IF;
END $$;

INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES ('20000000-0000-0000-0000-000000000106','INITIATING',0);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-000000000106','20000000-0000-0000-0000-000000000106','00000000-0000-0000-0000-00000000aa01','INITIATOR');
INSERT INTO public.async_response(async_response_id,session_participation_id)
VALUES ('40000000-0000-0000-0000-000000000106','30000000-0000-0000-0000-000000000106');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_mark_async_invite_ready('20000000-0000-0000-0000-000000000106','00000000-0000-0000-0000-00000000aa01','10000000-0000-0000-0000-00000000aa01',0,
      ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'50000000-0000-0000-0000-00000000aa04'::uuid],
      'invite-preexisting-response',decode(repeat('39',32),'hex'));
    RAISE EXCEPTION 'preexisting initiator response unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='preexisting initiator response unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator response already exists' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected preexisting-response error: %',SQLERRM; END IF;
  END;
  IF NOT EXISTS (SELECT 1 FROM public.async_response WHERE async_response_id='40000000-0000-0000-0000-000000000106') THEN RAISE EXCEPTION 'preexisting response was overwritten/deleted'; END IF;
END $$;

INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES ('20000000-0000-0000-0000-000000000107','INITIATING',0);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role)
VALUES ('30000000-0000-0000-0000-000000000107','20000000-0000-0000-0000-000000000107','00000000-0000-0000-0000-00000000aa01','INITIATOR');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_mark_async_invite_ready('20000000-0000-0000-0000-000000000107','00000000-0000-0000-0000-00000000aa01','10000000-0000-0000-0000-00000000aa01',0,
      ARRAY['50000000-0000-0000-0000-00000000aa01'::uuid,'50000000-0000-0000-0000-00000000aa02'::uuid,'50000000-0000-0000-0000-00000000aa03'::uuid,'59999999-9999-4999-8999-999999999999'::uuid],
      'invite-missing-media',decode(repeat('3a',32),'hex'));
    RAISE EXCEPTION 'missing media unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='missing media unexpectedly accepted' THEN RAISE; END IF;
    IF position('initiator media assets are not eligible' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected missing-media error: %',SQLERRM; END IF;
  END;
  IF EXISTS (SELECT 1 FROM public.async_response WHERE session_participation_id='30000000-0000-0000-0000-000000000107') THEN RAISE EXCEPTION 'missing media left partial response'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000107'
      AND state='INITIATING' AND resource_version=0 AND invite_ready_at IS NULL AND response_start_deadline_at IS NULL
  ) THEN RAISE EXCEPTION 'missing media mutated lifecycle/version/anchors'; END IF;
END $$;

ROLLBACK;
SELECT 'mark_async_invite_ready_command_test PASS' AS result;
