BEGIN;

-- Shared participants and protected sessions.
INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-00000000aa10','Save Cut Initiator'),
('00000000-0000-0000-0000-00000000bb10','Save Cut Responder'),
('00000000-0000-0000-0000-00000000cc10','Save Cut Other');

INSERT INTO public.protected_access_session(
  protected_access_session_id,participant_id,session_token_hash,created_at,expires_at,revoked_at
) VALUES
('10000000-0000-0000-0000-00000000bb10','00000000-0000-0000-0000-00000000bb10',decode(repeat('11',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',NULL),
('10000000-0000-0000-0000-00000000bb11','00000000-0000-0000-0000-00000000bb10',decode(repeat('12',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',NULL),
('10000000-0000-0000-0000-00000000bb12','00000000-0000-0000-0000-00000000bb10',decode(repeat('13',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',transaction_timestamp()),
('10000000-0000-0000-0000-00000000bb13','00000000-0000-0000-0000-00000000bb10',decode(repeat('14',32),'hex'),transaction_timestamp()-interval '2 hours',transaction_timestamp()-interval '1 hour',NULL),
('10000000-0000-0000-0000-00000000cc10','00000000-0000-0000-0000-00000000cc10',decode(repeat('15',32),'hex'),transaction_timestamp(),transaction_timestamp()+interval '2 days',NULL);

-- Canonical media. MediaAsset existence is the current accepted/canonical identity boundary.
INSERT INTO public.media_asset(
  media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type
) VALUES
('50000000-0000-0000-0000-00000000aa11','00000000-0000-0000-0000-00000000aa10','TENCENT_COS','save-cut/a1.jpg',decode(repeat('21',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa12','00000000-0000-0000-0000-00000000aa10','TENCENT_COS','save-cut/a2.jpg',decode(repeat('22',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa13','00000000-0000-0000-0000-00000000aa10','TENCENT_COS','save-cut/a3.jpg',decode(repeat('23',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000aa14','00000000-0000-0000-0000-00000000aa10','TENCENT_COS','save-cut/a4.jpg',decode(repeat('24',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb11','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/b1.jpg',decode(repeat('31',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb12','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/b2.jpg',decode(repeat('32',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb13','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/b3.jpg',decode(repeat('33',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb14','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/b4.jpg',decode(repeat('34',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb15','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/b1-retake.jpg',decode(repeat('35',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb16','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/b2-retake.jpg',decode(repeat('36',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb17','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/b3-retake.jpg',decode(repeat('37',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb18','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/b4-retake.jpg',decode(repeat('38',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bb19','00000000-0000-0000-0000-00000000bb10','TENCENT_COS','save-cut/not-image.bin',decode(repeat('39',32),'hex'),'application/octet-stream'),
('50000000-0000-0000-0000-00000000cc11','00000000-0000-0000-0000-00000000cc10','TENCENT_COS','save-cut/foreign.jpg',decode(repeat('3a',32),'hex'),'image/jpeg');

-- Main RESPONDING fixture. A-side is materialized before invite_ready_at becomes non-null,
-- matching the production freeze invariant.
INSERT INTO public.async_session(async_session_id,state,resource_version)
VALUES ('20000000-0000-0000-0000-000000000210','INITIATING',10);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-00000000aa10','20000000-0000-0000-0000-000000000210','00000000-0000-0000-0000-00000000aa10','INITIATOR'),
('30000000-0000-0000-0000-00000000bb10','20000000-0000-0000-0000-000000000210','00000000-0000-0000-0000-00000000bb10','RESPONDER');
INSERT INTO public.async_response(async_response_id,session_participation_id)
VALUES ('40000000-0000-0000-0000-00000000aa10','30000000-0000-0000-0000-00000000aa10');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES
('40000000-0000-0000-0000-00000000aa10',1::smallint,'50000000-0000-0000-0000-00000000aa11'),
('40000000-0000-0000-0000-00000000aa10',2::smallint,'50000000-0000-0000-0000-00000000aa12'),
('40000000-0000-0000-0000-00000000aa10',3::smallint,'50000000-0000-0000-0000-00000000aa13'),
('40000000-0000-0000-0000-00000000aa10',4::smallint,'50000000-0000-0000-0000-00000000aa14');
UPDATE public.async_session SET
  state='RESPONDING',
  invite_ready_at=transaction_timestamp()-interval '2 hours',
  response_start_deadline_at=transaction_timestamp()+interval '5 days',
  responding_started_at=transaction_timestamp()-interval '1 hour',
  responding_deadline_at=transaction_timestamp()+interval '23 hours',
  current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb10',
  active_editing_access_session_id='10000000-0000-0000-0000-00000000bb10'
WHERE async_session_id='20000000-0000-0000-0000-000000000210';
INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash,expires_at)
VALUES ('30000000-0000-0000-0000-00000000bb10',decode(repeat('41',32),'hex'),transaction_timestamp()+interval '23 hours');

DO $$
DECLARE
  b1 jsonb;
  replay jsonb;
  v_response_id uuid;
  v_version bigint;
  v_count integer;
  v_updated_before timestamptz;
  v_updated_after timestamptz;
  v_snapshot jsonb;
BEGIN
  b1 := public.hbd_save_async_response_cut(
    '20000000-0000-0000-0000-000000000210',
    '30000000-0000-0000-0000-00000000bb10',
    '10000000-0000-0000-0000-00000000bb10',
    1::smallint,
    '50000000-0000-0000-0000-00000000bb11',
    10,
    'save-cut-b1',decode(repeat('51',32),'hex')
  );

  IF (SELECT count(*) FROM jsonb_object_keys(b1)) <> 8
     OR NOT (b1 ?& ARRAY['async_session_id','responder_participation_id','state','resource_version','responding_started_at','responding_deadline_at','saved_at','response_media']) THEN
    RAISE EXCEPTION 'save B1 outcome shape invalid: %', b1;
  END IF;
  IF b1->>'state' <> 'RESPONDING' OR (b1->>'resource_version')::bigint <> 11 THEN
    RAISE EXCEPTION 'save B1 lifecycle/version invalid: %', b1;
  END IF;
  IF (b1->>'responder_participation_id')::uuid <> '30000000-0000-0000-0000-00000000bb10'::uuid THEN
    RAISE EXCEPTION 'save B1 participation mismatch';
  END IF;
  IF (b1->'response_media') <> jsonb_build_array(jsonb_build_object('cut_position',1,'media_asset_id','50000000-0000-0000-0000-00000000bb11'::uuid)) THEN
    RAISE EXCEPTION 'save B1 response_media snapshot invalid: %', b1->'response_media';
  END IF;

  SELECT ar.async_response_id INTO v_response_id
  FROM public.async_response ar
  WHERE ar.session_participation_id='30000000-0000-0000-0000-00000000bb10';
  IF v_response_id IS NULL THEN RAISE EXCEPTION 'save B1 did not create responder AsyncResponse'; END IF;
  SELECT count(*) INTO v_count FROM public.async_response_media WHERE async_response_id=v_response_id;
  IF v_count <> 1 THEN RAISE EXCEPTION 'save B1 expected one responder media row, got %', v_count; END IF;
  SELECT resource_version INTO v_version FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000210';
  IF v_version <> 11 THEN RAISE EXCEPTION 'save B1 persisted version expected 11 got %',v_version; END IF;

  replay := public.hbd_save_async_response_cut(
    '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
    1::smallint,'50000000-0000-0000-0000-00000000bb11',10,'save-cut-b1',decode(repeat('51',32),'hex')
  );
  IF replay <> b1 THEN RAISE EXCEPTION 'exact replay changed B1 outcome'; END IF;
  SELECT resource_version INTO v_version FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000210';
  IF v_version <> 11 THEN RAISE EXCEPTION 'exact replay advanced version'; END IF;

  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
      2::smallint,'50000000-0000-0000-0000-00000000bb12',11,'save-cut-b1',decode(repeat('52',32),'hex'));
    RAISE EXCEPTION 'save-cut idempotency mismatch unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='save-cut idempotency mismatch unexpectedly accepted' THEN RAISE; END IF;
    IF position('idempotency request hash mismatch' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected save-cut mismatch error: %',SQLERRM; END IF;
  END;

  BEGIN
    PERFORM public.hbd_release_claim(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
      11,'release-after-command-b1',decode(repeat('53',32),'hex'));
    RAISE EXCEPTION 'release after command-confirmed B1 unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='release after command-confirmed B1 unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder claim cannot be released after first confirmed cut' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected release-after-B1 error: %',SQLERRM; END IF;
  END;

  -- Cannot skip B2 and confirm B3.
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
      3::smallint,'50000000-0000-0000-0000-00000000bb13',11,'save-cut-skip-b2',decode(repeat('54',32),'hex'));
    RAISE EXCEPTION 'B3 before B2 unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='B3 before B2 unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder response sequence conflict' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected sequence error: %',SQLERRM; END IF;
  END;
  IF EXISTS (SELECT 1 FROM public.idempotency_record WHERE command_scope='ASYNC_SAVE_RESPONSE_CUT' AND idempotency_key='save-cut-skip-b2') THEN
    RAISE EXCEPTION 'failed sequence command persisted idempotency outcome';
  END IF;
  IF EXISTS (SELECT 1 FROM public.async_response_media WHERE async_response_id=v_response_id AND cut_position=3) THEN
    RAISE EXCEPTION 'failed B3 sequence command left partial media';
  END IF;

  -- Same media cannot occupy another B slot.
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
      2::smallint,'50000000-0000-0000-0000-00000000bb11',11,'save-cut-duplicate-media',decode(repeat('55',32),'hex'));
    RAISE EXCEPTION 'duplicate responder media unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='duplicate responder media unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder media asset already used in another cut' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected duplicate-media error: %',SQLERRM; END IF;
  END;

  -- Foreign-owned and non-image media both fail eligibility without mutation.
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
      2::smallint,'50000000-0000-0000-0000-00000000cc11',11,'save-cut-foreign',decode(repeat('56',32),'hex'));
    RAISE EXCEPTION 'foreign responder media unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='foreign responder media unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder media asset is not eligible' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected foreign-media error: %',SQLERRM; END IF;
  END;
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
      2::smallint,'50000000-0000-0000-0000-00000000bb19',11,'save-cut-non-image',decode(repeat('57',32),'hex'));
    RAISE EXCEPTION 'non-image responder media unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='non-image responder media unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder media asset is not eligible' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected non-image error: %',SQLERRM; END IF;
  END;
  SELECT resource_version INTO v_version FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000210';
  IF v_version <> 11 THEN RAISE EXCEPTION 'failed media checks changed version'; END IF;

  -- Wrong participation and same participant on a non-active browser both fail authority.
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000aa10','10000000-0000-0000-0000-00000000bb10',
      2::smallint,'50000000-0000-0000-0000-00000000bb12',11,'save-cut-wrong-participation',decode(repeat('58',32),'hex'));
    RAISE EXCEPTION 'wrong responder participation unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='wrong responder participation unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder participation invalid' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected responder-participation error: %',SQLERRM; END IF;
  END;
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb11',
      2::smallint,'50000000-0000-0000-0000-00000000bb12',11,'save-cut-inactive-browser',decode(repeat('59',32),'hex'));
    RAISE EXCEPTION 'non-active responder browser unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='non-active responder browser unexpectedly accepted' THEN RAISE; END IF;
    IF position('protected access session is not active editor' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected active-editor error: %',SQLERRM; END IF;
  END;

  -- Revoked/expired protected access sessions fail even when temporarily made the active pointer in fixture state.
  UPDATE public.async_session SET active_editing_access_session_id='10000000-0000-0000-0000-00000000bb12'
  WHERE async_session_id='20000000-0000-0000-0000-000000000210';
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb12',
      2::smallint,'50000000-0000-0000-0000-00000000bb12',11,'save-cut-revoked',decode(repeat('5a',32),'hex'));
    RAISE EXCEPTION 'revoked protected session unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='revoked protected session unexpectedly accepted' THEN RAISE; END IF;
    IF position('protected access session is not valid for responder' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected revoked-session error: %',SQLERRM; END IF;
  END;
  UPDATE public.async_session SET active_editing_access_session_id='10000000-0000-0000-0000-00000000bb13'
  WHERE async_session_id='20000000-0000-0000-0000-000000000210';
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb13',
      2::smallint,'50000000-0000-0000-0000-00000000bb12',11,'save-cut-expired-access',decode(repeat('5b',32),'hex'));
    RAISE EXCEPTION 'expired protected session unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='expired protected session unexpectedly accepted' THEN RAISE; END IF;
    IF position('protected access session is not valid for responder' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected expired-session error: %',SQLERRM; END IF;
  END;
  UPDATE public.async_session SET active_editing_access_session_id='10000000-0000-0000-0000-00000000bb10'
  WHERE async_session_id='20000000-0000-0000-0000-000000000210';

  -- B2 is the next valid append.
  PERFORM public.hbd_save_async_response_cut(
    '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
    2::smallint,'50000000-0000-0000-0000-00000000bb12',11,'save-cut-b2',decode(repeat('5c',32),'hex'));
  SELECT resource_version INTO v_version FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000210';
  IF v_version <> 12 THEN RAISE EXCEPTION 'save B2 version expected 12 got %',v_version; END IF;

  SELECT updated_at INTO v_updated_before FROM public.async_response WHERE async_response_id=v_response_id;
  v_snapshot := public.hbd_save_async_response_cut(
    '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
    2::smallint,'50000000-0000-0000-0000-00000000bb12',12,'save-cut-b2-noop',decode(repeat('5d',32),'hex'));
  SELECT updated_at INTO v_updated_after FROM public.async_response WHERE async_response_id=v_response_id;
  IF (v_snapshot->>'resource_version')::bigint <> 12 OR v_updated_after IS DISTINCT FROM v_updated_before THEN
    RAISE EXCEPTION 'same-slot/same-media no-op changed version or updated_at';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.idempotency_record WHERE command_scope='ASYNC_SAVE_RESPONSE_CUT' AND idempotency_key='save-cut-b2-noop') THEN
    RAISE EXCEPTION 'semantic no-op did not persist idempotency outcome';
  END IF;

  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
      2::smallint,'50000000-0000-0000-0000-00000000bb12',11,'save-cut-b2-stale-noop',decode(repeat('5e',32),'hex'));
    RAISE EXCEPTION 'stale same-media save unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='stale same-media save unexpectedly accepted' THEN RAISE; END IF;
    IF position('stale resource version' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected stale no-op error: %',SQLERRM; END IF;
  END;

  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
      4::smallint,'50000000-0000-0000-0000-00000000bb14',12,'save-cut-b4-before-b3',decode(repeat('5f',32),'hex'));
    RAISE EXCEPTION 'B4 before B3 unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='B4 before B3 unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder response sequence conflict' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected B4 sequence error: %',SQLERRM; END IF;
  END;

  v_snapshot := public.hbd_save_async_response_cut(
    '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
    3::smallint,'50000000-0000-0000-0000-00000000bb13',12,'save-cut-b3',decode(repeat('60',32),'hex'));
  IF (v_snapshot->>'resource_version')::bigint <> 13 THEN RAISE EXCEPTION 'B3 version invalid'; END IF;
  v_snapshot := public.hbd_save_async_response_cut(
    '20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',
    4::smallint,'50000000-0000-0000-0000-00000000bb14',13,'save-cut-b4',decode(repeat('61',32),'hex'));
  IF (v_snapshot->>'resource_version')::bigint <> 14 OR jsonb_array_length(v_snapshot->'response_media') <> 4 THEN
    RAISE EXCEPTION 'B4 complete-prefix outcome invalid: %',v_snapshot;
  END IF;

  -- Replace every already-confirmed slot; each is a logical mutation and advances exactly once.
  PERFORM public.hbd_save_async_response_cut('20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',1::smallint,'50000000-0000-0000-0000-00000000bb15',14,'replace-b1',decode(repeat('62',32),'hex'));
  PERFORM public.hbd_save_async_response_cut('20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',2::smallint,'50000000-0000-0000-0000-00000000bb16',15,'replace-b2',decode(repeat('63',32),'hex'));
  PERFORM public.hbd_save_async_response_cut('20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',3::smallint,'50000000-0000-0000-0000-00000000bb17',16,'replace-b3',decode(repeat('64',32),'hex'));
  v_snapshot := public.hbd_save_async_response_cut('20000000-0000-0000-0000-000000000210','30000000-0000-0000-0000-00000000bb10','10000000-0000-0000-0000-00000000bb10',4::smallint,'50000000-0000-0000-0000-00000000bb18',17,'replace-b4',decode(repeat('65',32),'hex'));
  IF (v_snapshot->>'resource_version')::bigint <> 18 THEN RAISE EXCEPTION 'replacement version chain invalid'; END IF;
  IF v_snapshot->'response_media' <> jsonb_build_array(
      jsonb_build_object('cut_position',1,'media_asset_id','50000000-0000-0000-0000-00000000bb15'::uuid),
      jsonb_build_object('cut_position',2,'media_asset_id','50000000-0000-0000-0000-00000000bb16'::uuid),
      jsonb_build_object('cut_position',3,'media_asset_id','50000000-0000-0000-0000-00000000bb17'::uuid),
      jsonb_build_object('cut_position',4,'media_asset_id','50000000-0000-0000-0000-00000000bb18'::uuid)
    ) THEN RAISE EXCEPTION 'replacement response_media snapshot invalid: %',v_snapshot->'response_media'; END IF;
END $$;
-- Additional fixtures for atomic rejection paths. A-side is inserted while invite_ready_at is NULL.
INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES
('20000000-0000-0000-0000-000000000211','INITIATING',20),
('20000000-0000-0000-0000-000000000212','INITIATING',30),
('20000000-0000-0000-0000-000000000213','INITIATING',40),
('20000000-0000-0000-0000-000000000214','INITIATING',50);

INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-00000000aa11','20000000-0000-0000-0000-000000000211','00000000-0000-0000-0000-00000000aa10','INITIATOR'),
('30000000-0000-0000-0000-00000000bb11','20000000-0000-0000-0000-000000000211','00000000-0000-0000-0000-00000000bb10','RESPONDER'),
('30000000-0000-0000-0000-00000000aa12','20000000-0000-0000-0000-000000000212','00000000-0000-0000-0000-00000000aa10','INITIATOR'),
('30000000-0000-0000-0000-00000000bb12','20000000-0000-0000-0000-000000000212','00000000-0000-0000-0000-00000000bb10','RESPONDER'),
('30000000-0000-0000-0000-00000000aa13','20000000-0000-0000-0000-000000000213','00000000-0000-0000-0000-00000000aa10','INITIATOR'),
('30000000-0000-0000-0000-00000000bb13','20000000-0000-0000-0000-000000000213','00000000-0000-0000-0000-00000000bb10','RESPONDER'),
('30000000-0000-0000-0000-00000000aa14','20000000-0000-0000-0000-000000000214','00000000-0000-0000-0000-00000000aa10','INITIATOR'),
('30000000-0000-0000-0000-00000000bb14','20000000-0000-0000-0000-000000000214','00000000-0000-0000-0000-00000000bb10','RESPONDER');

INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES
('40000000-0000-0000-0000-00000000aa11','30000000-0000-0000-0000-00000000aa11'),
('40000000-0000-0000-0000-00000000aa12','30000000-0000-0000-0000-00000000aa12'),
('40000000-0000-0000-0000-00000000aa13','30000000-0000-0000-0000-00000000aa13'),
('40000000-0000-0000-0000-00000000aa14','30000000-0000-0000-0000-00000000aa14');

INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id)
SELECT response_id,cut_position,media_asset_id
FROM (VALUES
('40000000-0000-0000-0000-00000000aa11'::uuid,1::smallint,'50000000-0000-0000-0000-00000000aa11'::uuid),
('40000000-0000-0000-0000-00000000aa11'::uuid,2::smallint,'50000000-0000-0000-0000-00000000aa12'::uuid),
('40000000-0000-0000-0000-00000000aa11'::uuid,3::smallint,'50000000-0000-0000-0000-00000000aa13'::uuid),
('40000000-0000-0000-0000-00000000aa11'::uuid,4::smallint,'50000000-0000-0000-0000-00000000aa14'::uuid),
('40000000-0000-0000-0000-00000000aa12'::uuid,1::smallint,'50000000-0000-0000-0000-00000000aa11'::uuid),
('40000000-0000-0000-0000-00000000aa12'::uuid,2::smallint,'50000000-0000-0000-0000-00000000aa12'::uuid),
('40000000-0000-0000-0000-00000000aa12'::uuid,3::smallint,'50000000-0000-0000-0000-00000000aa13'::uuid),
('40000000-0000-0000-0000-00000000aa12'::uuid,4::smallint,'50000000-0000-0000-0000-00000000aa14'::uuid),
('40000000-0000-0000-0000-00000000aa13'::uuid,1::smallint,'50000000-0000-0000-0000-00000000aa11'::uuid),
('40000000-0000-0000-0000-00000000aa13'::uuid,2::smallint,'50000000-0000-0000-0000-00000000aa12'::uuid),
('40000000-0000-0000-0000-00000000aa13'::uuid,3::smallint,'50000000-0000-0000-0000-00000000aa13'::uuid),
('40000000-0000-0000-0000-00000000aa13'::uuid,4::smallint,'50000000-0000-0000-0000-00000000aa14'::uuid),
('40000000-0000-0000-0000-00000000aa14'::uuid,1::smallint,'50000000-0000-0000-0000-00000000aa11'::uuid),
('40000000-0000-0000-0000-00000000aa14'::uuid,2::smallint,'50000000-0000-0000-0000-00000000aa12'::uuid),
('40000000-0000-0000-0000-00000000aa14'::uuid,3::smallint,'50000000-0000-0000-0000-00000000aa13'::uuid),
('40000000-0000-0000-0000-00000000aa14'::uuid,4::smallint,'50000000-0000-0000-0000-00000000aa14'::uuid)
) AS seed(response_id,cut_position,media_asset_id);

UPDATE public.async_session SET
  state='RESPONDING',invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',
  responding_started_at=transaction_timestamp()-interval '1 hour',responding_deadline_at=transaction_timestamp()+interval '23 hours',
  current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb11',active_editing_access_session_id='10000000-0000-0000-0000-00000000bb10'
WHERE async_session_id='20000000-0000-0000-0000-000000000211';

UPDATE public.async_session SET
  state='WAITING',invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days'
WHERE async_session_id='20000000-0000-0000-0000-000000000212';

UPDATE public.async_session SET
  state='RESPONDING',invite_ready_at=transaction_timestamp()-interval '3 days',response_start_deadline_at=transaction_timestamp()+interval '4 days',
  responding_started_at=transaction_timestamp()-interval '2 hours',responding_deadline_at=transaction_timestamp()-interval '1 hour',
  current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb13',active_editing_access_session_id='10000000-0000-0000-0000-00000000bb10'
WHERE async_session_id='20000000-0000-0000-0000-000000000213';

UPDATE public.async_session SET
  state='RESPONDING',invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',
  responding_started_at=transaction_timestamp()-interval '1 hour',responding_deadline_at=transaction_timestamp()+interval '23 hours',
  current_editor_session_participation_id='30000000-0000-0000-0000-00000000bb14',active_editing_access_session_id='10000000-0000-0000-0000-00000000bb10'
WHERE async_session_id='20000000-0000-0000-0000-000000000214';
INSERT INTO public.async_response(async_response_id,session_participation_id)
VALUES ('40000000-0000-0000-0000-00000000bb14','30000000-0000-0000-0000-00000000bb14');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES
('40000000-0000-0000-0000-00000000bb14',1::smallint,'50000000-0000-0000-0000-00000000bb11'),
('40000000-0000-0000-0000-00000000bb14',3::smallint,'50000000-0000-0000-0000-00000000bb13');

DO $$
DECLARE v_version bigint;
BEGIN
  -- B2 before B1 must not create a responder response or idempotency record.
  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000211','30000000-0000-0000-0000-00000000bb11','10000000-0000-0000-0000-00000000bb10',
      2::smallint,'50000000-0000-0000-0000-00000000bb12',20,'save-cut-b2-before-b1',decode(repeat('71',32),'hex'));
    RAISE EXCEPTION 'B2 before B1 unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='B2 before B1 unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder response sequence conflict' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected B2-before-B1 error: %',SQLERRM; END IF;
  END;
  IF EXISTS (SELECT 1 FROM public.async_response WHERE session_participation_id='30000000-0000-0000-0000-00000000bb11') THEN
    RAISE EXCEPTION 'invalid B2 created responder AsyncResponse';
  END IF;
  SELECT resource_version INTO v_version FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000211';
  IF v_version<>20 THEN RAISE EXCEPTION 'invalid B2 changed version'; END IF;
  IF EXISTS (SELECT 1 FROM public.idempotency_record WHERE command_scope='ASYNC_SAVE_RESPONSE_CUT' AND idempotency_key='save-cut-b2-before-b1') THEN
    RAISE EXCEPTION 'invalid B2 persisted idempotency outcome';
  END IF;

  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000212','30000000-0000-0000-0000-00000000bb12','10000000-0000-0000-0000-00000000bb10',
      1::smallint,'50000000-0000-0000-0000-00000000bb11',30,'save-cut-waiting',decode(repeat('72',32),'hex'));
    RAISE EXCEPTION 'save outside RESPONDING unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='save outside RESPONDING unexpectedly accepted' THEN RAISE; END IF;
    IF position('async session is not responding' in lower(SQLERRM))=0 THEN RAISE EXCEPTION 'unexpected non-RESPONDING error: %',SQLERRM; END IF;
  END;

  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000213','30000000-0000-0000-0000-00000000bb13','10000000-0000-0000-0000-00000000bb10',
      1::smallint,'50000000-0000-0000-0000-00000000bb11',40,'save-cut-expired-window',decode(repeat('73',32),'hex'));
    RAISE EXCEPTION 'expired responding window unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='expired responding window unexpectedly accepted' THEN RAISE; END IF;
    IF position('responding window has expired' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected deadline error: %',SQLERRM; END IF;
  END;

  BEGIN
    PERFORM public.hbd_save_async_response_cut(
      '20000000-0000-0000-0000-000000000214','30000000-0000-0000-0000-00000000bb14','10000000-0000-0000-0000-00000000bb10',
      2::smallint,'50000000-0000-0000-0000-00000000bb12',50,'save-cut-sparse-state',decode(repeat('74',32),'hex'));
    RAISE EXCEPTION 'sparse responder state unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='sparse responder state unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder response media prefix invariant violated' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected sparse-prefix error: %',SQLERRM; END IF;
  END;
  SELECT resource_version INTO v_version FROM public.async_session WHERE async_session_id='20000000-0000-0000-0000-000000000214';
  IF v_version<>50 THEN RAISE EXCEPTION 'sparse-state rejection changed version'; END IF;
END $$;

ROLLBACK;
SELECT 'save_async_response_cut_command_test PASS' AS result;




