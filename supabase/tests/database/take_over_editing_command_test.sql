BEGIN;

INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-00000000aa20','Takeover Initiator'),
('00000000-0000-0000-0000-00000000bb20','Takeover Responder'),
('00000000-0000-0000-0000-00000000cc20','Takeover Other');

INSERT INTO public.protected_access_session(
  protected_access_session_id,participant_id,session_token_hash,created_at,expires_at,revoked_at
) VALUES
('10000000-0000-0000-0000-00000000bb20','00000000-0000-0000-0000-00000000bb20',decode(repeat('81',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',NULL),
('10000000-0000-0000-0000-00000000bb21','00000000-0000-0000-0000-00000000bb20',decode(repeat('82',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',NULL),
('10000000-0000-0000-0000-00000000bb22','00000000-0000-0000-0000-00000000bb20',decode(repeat('83',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',transaction_timestamp()),
('10000000-0000-0000-0000-00000000bb23','00000000-0000-0000-0000-00000000bb20',decode(repeat('84',32),'hex'),transaction_timestamp()-interval '2 hours',transaction_timestamp()-interval '1 hour',NULL),
('10000000-0000-0000-0000-00000000cc20','00000000-0000-0000-0000-00000000cc20',decode(repeat('85',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',NULL);

INSERT INTO public.media_asset(
  media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type
) VALUES
('50000000-0000-0000-0000-00000000aa21','00000000-0000-0000-0000-00000000aa20','TENCENT_COS','takeover/a1.jpg',decode(repeat('91',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa22','00000000-0000-0000-0000-00000000aa20','TENCENT_COS','takeover/a2.jpg',decode(repeat('92',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa23','00000000-0000-0000-0000-00000000aa20','TENCENT_COS','takeover/a3.jpg',decode(repeat('93',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa24','00000000-0000-0000-0000-00000000aa20','TENCENT_COS','takeover/a4.jpg',decode(repeat('94',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb21','00000000-0000-0000-0000-00000000bb20','TENCENT_COS','takeover/b1.jpg',decode(repeat('95',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb22','00000000-0000-0000-0000-00000000bb20','TENCENT_COS','takeover/b2.jpg',decode(repeat('96',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb23','00000000-0000-0000-0000-00000000bb20','TENCENT_COS','takeover/b3.jpg',decode(repeat('97',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb24','00000000-0000-0000-0000-00000000bb20','TENCENT_COS','takeover/b4.jpg',decode(repeat('98',32),'hex'),'image/jpeg');

-- Main responder with B1+B2 already durable. Materialize A-side before Invite Ready freeze.
INSERT INTO public.async_session(async_session_id,state,resource_version)
VALUES ('20000000-0000-0000-0000-000000000220','INITIATING',20);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-00000000aa20','20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000aa20','INITIATOR'),
('30000000-0000-0000-0000-00000000bb20','20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20','RESPONDER');
INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES
('40000000-0000-0000-0000-00000000aa20','30000000-0000-0000-0000-00000000aa20');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES
('40000000-0000-0000-0000-00000000aa20',1,'50000000-0000-0000-0000-00000000aa21'),
('40000000-0000-0000-0000-00000000aa20',2,'50000000-0000-0000-0000-00000000aa22'),
('40000000-0000-0000-0000-00000000aa20',3,'50000000-0000-0000-0000-00000000aa23'),
('40000000-0000-0000-0000-00000000aa20',4,'50000000-0000-0000-0000-00000000aa24');
UPDATE public.async_session SET
 state='RESPONDING',invite_ready_at=transaction_timestamp()-interval '3 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',
 responding_started_at=transaction_timestamp()-interval '2 hours',responding_deadline_at=transaction_timestamp()+interval '22 hours',
 current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb20',active_editing_access_session_id='10000000-0000-0000-0000-00000000bb20'
WHERE async_session_id='20000000-0000-0000-0000-000000000220';
INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES
('40000000-0000-0000-0000-00000000bb20','30000000-0000-0000-0000-00000000bb20');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES
('40000000-0000-0000-0000-00000000bb20',1,'50000000-0000-0000-0000-00000000bb21'),
('40000000-0000-0000-0000-00000000bb20',2,'50000000-0000-0000-0000-00000000bb22');
INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash,expires_at)
VALUES ('30000000-0000-0000-0000-00000000bb20',decode(repeat('a1',32),'hex'),transaction_timestamp()+interval '22 hours');

DO $$
DECLARE
  v_before_started timestamptz;
  v_before_deadline timestamptz;
  v_before_editor uuid;
  v_before_a jsonb;
  v_before_b jsonb;
  v_outcome jsonb;
  v_replay jsonb;
  v_version bigint;
  v_active uuid;
BEGIN
  SELECT responding_started_at,responding_deadline_at,current_editor_session_participation_id
    INTO v_before_started,v_before_deadline,v_before_editor
  FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000220';
  SELECT jsonb_agg(jsonb_build_object('p',arm.cut_position,'m',arm.media_asset_id) ORDER BY arm.cut_position)
    INTO v_before_a FROM public.async_response_media arm WHERE arm.async_response_id='40000000-0000-0000-0000-00000000aa20';
  SELECT jsonb_agg(jsonb_build_object('p',arm.cut_position,'m',arm.media_asset_id) ORDER BY arm.cut_position)
    INTO v_before_b FROM public.async_response_media arm WHERE arm.async_response_id='40000000-0000-0000-0000-00000000bb20';

  v_outcome := public.hbd_take_over_editing(
    '20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',
    20,'takeover-main',decode(repeat('b1',32),'hex'));

  IF (SELECT count(*) FROM jsonb_object_keys(v_outcome)) <> 8
     OR NOT (v_outcome ?& ARRAY['async_session_id','responder_participation_id','state','resource_version','responding_started_at','responding_deadline_at','taken_over_at','response_media']) THEN
    RAISE EXCEPTION 'takeover outcome shape invalid: %',v_outcome;
  END IF;
  IF v_outcome->>'state' <> 'RESPONDING' OR (v_outcome->>'resource_version')::bigint <> 21 THEN
    RAISE EXCEPTION 'takeover outcome lifecycle/version invalid: %',v_outcome;
  END IF;
  IF (v_outcome->>'responder_participation_id')::uuid <> '30000000-0000-0000-0000-00000000bb20'::uuid THEN
    RAISE EXCEPTION 'takeover responder participation mismatch';
  END IF;
  IF v_outcome->'response_media' <> jsonb_build_array(
      jsonb_build_object('cut_position',1,'media_asset_id','50000000-0000-0000-0000-00000000bb21'::uuid),
      jsonb_build_object('cut_position',2,'media_asset_id','50000000-0000-0000-0000-00000000bb22'::uuid)
    ) THEN RAISE EXCEPTION 'takeover B snapshot invalid: %',v_outcome->'response_media'; END IF;

  SELECT resource_version,active_editing_access_session_id INTO v_version,v_active
  FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000220';
  IF v_version<>21 OR v_active<>'10000000-0000-0000-0000-00000000bb21'::uuid THEN
    RAISE EXCEPTION 'takeover pointer/version not persisted';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.async_session
    WHERE async_session_id='20000000-0000-0000-0000-000000000220'
      AND (current_editor_session_participation_id IS DISTINCT FROM v_before_editor
        OR responding_started_at IS DISTINCT FROM v_before_started
        OR responding_deadline_at IS DISTINCT FROM v_before_deadline)
  ) THEN RAISE EXCEPTION 'takeover changed responder participation or timing'; END IF;
  IF (SELECT jsonb_agg(jsonb_build_object('p',arm.cut_position,'m',arm.media_asset_id) ORDER BY arm.cut_position) FROM public.async_response_media arm WHERE arm.async_response_id='40000000-0000-0000-0000-00000000aa20') IS DISTINCT FROM v_before_a THEN
    RAISE EXCEPTION 'takeover mutated A-side rows';
  END IF;
  IF (SELECT jsonb_agg(jsonb_build_object('p',arm.cut_position,'m',arm.media_asset_id) ORDER BY arm.cut_position) FROM public.async_response_media arm WHERE arm.async_response_id='40000000-0000-0000-0000-00000000bb20') IS DISTINCT FROM v_before_b THEN
    RAISE EXCEPTION 'takeover mutated B-side rows';
  END IF;

  -- Exact replay must win before same-editor/stale checks.
  v_replay := public.hbd_take_over_editing(
    '20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',
    20,'takeover-main',decode(repeat('b1',32),'hex'));
  IF v_replay<>v_outcome THEN RAISE EXCEPTION 'exact takeover replay changed outcome'; END IF;

  BEGIN
    PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',21,'takeover-same-editor',decode(repeat('b2',32),'hex'));
    RAISE EXCEPTION 'same-editor takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='same-editor takeover unexpectedly accepted' THEN RAISE; END IF;
    IF position('protected access session is already active editor' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected same-editor error: %',SQLERRM; END IF;
  END;

  BEGIN
    PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000cc20','10000000-0000-0000-0000-00000000cc20',21,'takeover-foreign-participant',decode(repeat('b3',32),'hex'));
    RAISE EXCEPTION 'foreign participant takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='foreign participant takeover unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder participation invalid' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected foreign participant error: %',SQLERRM; END IF;
  END;

  BEGIN
    PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000cc20',21,'takeover-foreign-pas',decode(repeat('b4',32),'hex'));
    RAISE EXCEPTION 'foreign PAS takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='foreign PAS takeover unexpectedly accepted' THEN RAISE; END IF;
    IF position('protected access session is not valid for responder' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected foreign PAS error: %',SQLERRM; END IF;
  END;

  FOR v_active IN SELECT unnest(ARRAY['10000000-0000-0000-0000-00000000bb22'::uuid,'10000000-0000-0000-0000-00000000bb23'::uuid]) LOOP
    BEGIN
      PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20',v_active,21,'takeover-invalid-pas-'||right(v_active::text,2),decode(repeat('ba',32),'hex'));
      RAISE EXCEPTION 'invalid PAS takeover unexpectedly accepted';
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM='invalid PAS takeover unexpectedly accepted' THEN RAISE; END IF;
      IF position('protected access session is not valid for responder' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected invalid PAS error: %',SQLERRM; END IF;
    END;
  END LOOP;

  BEGIN
    PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb20',20,'takeover-stale',decode(repeat('b5',32),'hex'));
    RAISE EXCEPTION 'stale takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='stale takeover unexpectedly accepted' THEN RAISE; END IF;
    IF position('stale resource version' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected stale takeover error: %',SQLERRM; END IF;
  END;

  BEGIN
    PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb20',21,'takeover-main',decode(repeat('ff',32),'hex'));
    RAISE EXCEPTION 'idempotency mismatch unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='idempotency mismatch unexpectedly accepted' THEN RAISE; END IF;
    IF position('idempotency request hash mismatch' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected idempotency mismatch error: %',SQLERRM; END IF;
  END;

  -- Old browser may no longer save; new active browser can save B3 from fresh version.
  BEGIN
    PERFORM public.hbd_save_async_response_cut('20000000-0000-0000-0000-000000000220','30000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb20',3::smallint,'50000000-0000-0000-0000-00000000bb23',21,'old-browser-save',decode(repeat('b6',32),'hex'));
    RAISE EXCEPTION 'old browser save unexpectedly accepted after takeover';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='old browser save unexpectedly accepted after takeover' THEN RAISE; END IF;
    IF position('protected access session is not active editor' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected old browser save error: %',SQLERRM; END IF;
  END;
  PERFORM public.hbd_save_async_response_cut('20000000-0000-0000-0000-000000000220','30000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',3::smallint,'50000000-0000-0000-0000-00000000bb23',21,'new-browser-save',decode(repeat('b7',32),'hex'));

  -- Replay still returns original B1+B2 snapshot after later B3 progress.
  v_replay := public.hbd_take_over_editing('20000000-0000-0000-0000-000000000220','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',20,'takeover-main',decode(repeat('b1',32),'hex'));
  IF v_replay<>v_outcome OR jsonb_array_length(v_replay->'response_media')<>2 THEN RAISE EXCEPTION 'takeover replay contaminated by later progress'; END IF;

  -- Post-B1 release remains forbidden after takeover.
  BEGIN
    PERFORM public.hbd_release_claim('20000000-0000-0000-0000-000000000220','30000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',22,'release-post-b1-takeover',decode(repeat('b8',32),'hex'));
    RAISE EXCEPTION 'release after durable progress unexpectedly accepted after takeover';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='release after durable progress unexpectedly accepted after takeover' THEN RAISE; END IF;
    IF position('responder claim cannot be released after first confirmed cut' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected post-B1 release error: %',SQLERRM; END IF;
  END;

  -- Completion sharing the old version root must be stale before completeness checks.
  BEGIN
    PERFORM public.hbd_complete_async_session('20000000-0000-0000-0000-000000000220','30000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',20,'complete-stale-after-takeover',decode(repeat('b9',32),'hex'));
    RAISE EXCEPTION 'stale completion unexpectedly accepted after takeover';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='stale completion unexpectedly accepted after takeover' THEN RAISE; END IF;
    IF position('stale resource version' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected stale completion error: %',SQLERRM; END IF;
  END;
END $$;

-- Guard fixtures: WAITING, expired window, missing active pointer, current-editor mismatch, sparse B state.
INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES
('20000000-0000-0000-0000-000000000221','WAITING',30),
('20000000-0000-0000-0000-000000000222','RESPONDING',40),
('20000000-0000-0000-0000-000000000223','RESPONDING',50),
('20000000-0000-0000-0000-000000000224','RESPONDING',60),
('20000000-0000-0000-0000-000000000225','RESPONDING',70);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-00000000aa21','20000000-0000-0000-0000-000000000221','00000000-0000-0000-0000-00000000aa20','INITIATOR'),('30000000-0000-0000-0000-00000000bb21','20000000-0000-0000-0000-000000000221','00000000-0000-0000-0000-00000000bb20','RESPONDER'),
('30000000-0000-0000-0000-00000000aa22','20000000-0000-0000-0000-000000000222','00000000-0000-0000-0000-00000000aa20','INITIATOR'),('30000000-0000-0000-0000-00000000bb22','20000000-0000-0000-0000-000000000222','00000000-0000-0000-0000-00000000bb20','RESPONDER'),
('30000000-0000-0000-0000-00000000aa23','20000000-0000-0000-0000-000000000223','00000000-0000-0000-0000-00000000aa20','INITIATOR'),('30000000-0000-0000-0000-00000000bb23','20000000-0000-0000-0000-000000000223','00000000-0000-0000-0000-00000000bb20','RESPONDER'),
('30000000-0000-0000-0000-00000000aa24','20000000-0000-0000-0000-000000000224','00000000-0000-0000-0000-00000000aa20','INITIATOR'),('30000000-0000-0000-0000-00000000bb24','20000000-0000-0000-0000-000000000224','00000000-0000-0000-0000-00000000bb20','RESPONDER'),
('30000000-0000-0000-0000-00000000aa25','20000000-0000-0000-0000-000000000225','00000000-0000-0000-0000-00000000aa20','INITIATOR'),('30000000-0000-0000-0000-00000000bb25','20000000-0000-0000-0000-000000000225','00000000-0000-0000-0000-00000000bb20','RESPONDER');

UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days' WHERE async_session_id='20000000-0000-0000-0000-000000000221';
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '3 days',response_start_deadline_at=transaction_timestamp()+interval '4 days',responding_started_at=transaction_timestamp()-interval '25 hours',responding_deadline_at=transaction_timestamp()-interval '1 hour',current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb22',active_editing_access_session_id='10000000-0000-0000-0000-00000000bb20' WHERE async_session_id='20000000-0000-0000-0000-000000000222';
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '1 hour',responding_deadline_at=transaction_timestamp()+interval '23 hours',current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb23',active_editing_access_session_id=NULL WHERE async_session_id='20000000-0000-0000-0000-000000000223';
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '1 hour',responding_deadline_at=transaction_timestamp()+interval '23 hours',current_editor_session_participation_id='30000000-0000-0000-0000-00000000aa24',active_editing_access_session_id='10000000-0000-0000-0000-00000000bb20' WHERE async_session_id='20000000-0000-0000-0000-000000000224';
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '1 hour',responding_deadline_at=transaction_timestamp()+interval '23 hours',current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb25',active_editing_access_session_id='10000000-0000-0000-0000-00000000bb20' WHERE async_session_id='20000000-0000-0000-0000-000000000225';
INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES ('40000000-0000-0000-0000-00000000bb25','30000000-0000-0000-0000-00000000bb25');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES
('40000000-0000-0000-0000-00000000bb25',1,'50000000-0000-0000-0000-00000000bb21'),
('40000000-0000-0000-0000-00000000bb25',3,'50000000-0000-0000-0000-00000000bb23');

DO $$
DECLARE v_version bigint; v_active uuid;
BEGIN
  BEGIN PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000221','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',30,'takeover-waiting',decode(repeat('c1',32),'hex')); RAISE EXCEPTION 'WAITING takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN IF SQLERRM='WAITING takeover unexpectedly accepted' THEN RAISE; END IF; IF position('async session is not responding' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected WAITING error: %',SQLERRM; END IF; END;
  BEGIN PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000222','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',40,'takeover-expired',decode(repeat('c2',32),'hex')); RAISE EXCEPTION 'expired takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN IF SQLERRM='expired takeover unexpectedly accepted' THEN RAISE; END IF; IF position('responding window has expired' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected deadline error: %',SQLERRM; END IF; END;
  BEGIN PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000223','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',50,'takeover-no-active',decode(repeat('c3',32),'hex')); RAISE EXCEPTION 'missing-active takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN IF SQLERRM='missing-active takeover unexpectedly accepted' THEN RAISE; END IF; IF position('active editing access session is missing' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected missing-active error: %',SQLERRM; END IF; END;
  BEGIN PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000224','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',60,'takeover-wrong-editor',decode(repeat('c4',32),'hex')); RAISE EXCEPTION 'wrong-editor takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN IF SQLERRM='wrong-editor takeover unexpectedly accepted' THEN RAISE; END IF; IF position('responder is not current editor' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected wrong-editor error: %',SQLERRM; END IF; END;
  BEGIN PERFORM public.hbd_take_over_editing('20000000-0000-0000-0000-000000000225','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',70,'takeover-sparse',decode(repeat('c5',32),'hex')); RAISE EXCEPTION 'sparse takeover unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN IF SQLERRM='sparse takeover unexpectedly accepted' THEN RAISE; END IF; IF position('responder response media prefix invariant violated' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected sparse error: %',SQLERRM; END IF; END;
  SELECT resource_version,active_editing_access_session_id INTO v_version,v_active FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000225';
  IF v_version<>70 OR v_active<>'10000000-0000-0000-0000-00000000bb20'::uuid THEN RAISE EXCEPTION 'sparse rejection mutated session'; END IF;
END $$;

-- Pre-B1 takeover keeps ReleaseClaim legal from the newly active PAS.
INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES ('20000000-0000-0000-0000-000000000226','RESPONDING',80);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-00000000aa26','20000000-0000-0000-0000-000000000226','00000000-0000-0000-0000-00000000aa20','INITIATOR'),
('30000000-0000-0000-0000-00000000bb26','20000000-0000-0000-0000-000000000226','00000000-0000-0000-0000-00000000bb20','RESPONDER');
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '1 hour',responding_deadline_at=transaction_timestamp()+interval '23 hours',current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb26',active_editing_access_session_id='10000000-0000-0000-0000-00000000bb20' WHERE async_session_id='20000000-0000-0000-0000-000000000226';
INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash,expires_at) VALUES ('30000000-0000-0000-0000-00000000bb26',decode(repeat('d1',32),'hex'),transaction_timestamp()+interval '23 hours');
DO $$
DECLARE v_take jsonb; v_release jsonb;
BEGIN
  v_take:=public.hbd_take_over_editing('20000000-0000-0000-0000-000000000226','00000000-0000-0000-0000-00000000bb20','10000000-0000-0000-0000-00000000bb21',80,'takeover-pre-b1',decode(repeat('d2',32),'hex'));
  IF jsonb_array_length(v_take->'response_media')<>0 OR (v_take->>'resource_version')::bigint<>81 THEN RAISE EXCEPTION 'pre-B1 takeover outcome invalid'; END IF;
  v_release:=public.hbd_release_claim('20000000-0000-0000-0000-000000000226','30000000-0000-0000-0000-00000000bb26','10000000-0000-0000-0000-00000000bb21',81,'release-after-pre-b1-takeover',decode(repeat('d3',32),'hex'));
  IF v_release->>'state'<>'WAITING' OR (v_release->>'resource_version')::bigint<>82 THEN RAISE EXCEPTION 'release after pre-B1 takeover invalid'; END IF;
END $$;

ROLLBACK;
SELECT 'take_over_editing_command_test PASS' AS result;
