BEGIN;

INSERT INTO public.participant(participant_id,display_name) VALUES
('00000000-0000-0000-0000-00000000ac30','Continue Initiator'),
('00000000-0000-0000-0000-00000000bc30','Continue Responder'),
('00000000-0000-0000-0000-00000000cc30','Continue Other');

INSERT INTO public.protected_access_session(
  protected_access_session_id,participant_id,session_token_hash,created_at,expires_at,revoked_at
) VALUES
('10000000-0000-0000-0000-00000000bc30','00000000-0000-0000-0000-00000000bc30',decode(repeat('31',32),'hex'),transaction_timestamp()-interval '1 hour',transaction_timestamp()+interval '2 days',NULL),
('10000000-0000-0000-0000-00000000bc31','00000000-0000-0000-0000-00000000bc30',decode(repeat('32',32),'hex'),transaction_timestamp()-interval '1 hour',transaction_timestamp()+interval '2 days',NULL),
('10000000-0000-0000-0000-00000000bc32','00000000-0000-0000-0000-00000000bc30',decode(repeat('33',32),'hex'),transaction_timestamp()-interval '2 hours',transaction_timestamp()+interval '2 days',transaction_timestamp()-interval '1 hour'),
('10000000-0000-0000-0000-00000000bc33','00000000-0000-0000-0000-00000000bc30',decode(repeat('34',32),'hex'),transaction_timestamp()-interval '2 hours',transaction_timestamp()-interval '1 hour',NULL),
('10000000-0000-0000-0000-00000000cc30','00000000-0000-0000-0000-00000000cc30',decode(repeat('35',32),'hex'),transaction_timestamp()-interval '1 hour',transaction_timestamp()+interval '2 days',NULL);

INSERT INTO public.media_asset(
  media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type
) VALUES
('50000000-0000-0000-0000-00000000bc31','00000000-0000-0000-0000-00000000bc30','TENCENT_COS','continue/b1.jpg',decode(repeat('41',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bc32','00000000-0000-0000-0000-00000000bc30','TENCENT_COS','continue/b2.jpg',decode(repeat('42',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bc33','00000000-0000-0000-0000-00000000bc30','TENCENT_COS','continue/b3.jpg',decode(repeat('43',32),'hex'),'image/jpeg'),
('50000000-0000-0000-0000-00000000bc34','00000000-0000-0000-0000-00000000bc30','TENCENT_COS','continue/b4.jpg',decode(repeat('44',32),'hex'),'image/jpeg');

-- Main B1 session.
INSERT INTO public.async_session(async_session_id,state,resource_version)
VALUES ('20000000-0000-0000-0000-000000000230','RESPONDING',30);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-00000000ac30','20000000-0000-0000-0000-000000000230','00000000-0000-0000-0000-00000000ac30','INITIATOR'),
('30000000-0000-0000-0000-00000000bc30','20000000-0000-0000-0000-000000000230','00000000-0000-0000-0000-00000000bc30','RESPONDER');
UPDATE public.async_session SET
 invite_ready_at=transaction_timestamp()-interval '3 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',
 responding_started_at=transaction_timestamp()-interval '2 hours',responding_deadline_at=transaction_timestamp()+interval '22 hours',
 current_editor_session_participation_id='30000000-0000-0000-0000-00000000bc30',active_editing_access_session_id='10000000-0000-0000-0000-00000000bc30'
WHERE async_session_id='20000000-0000-0000-0000-000000000230';
INSERT INTO public.async_response(async_response_id,session_participation_id)
VALUES ('40000000-0000-0000-0000-00000000bc30','30000000-0000-0000-0000-00000000bc30');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id)
VALUES ('40000000-0000-0000-0000-00000000bc30',1,'50000000-0000-0000-0000-00000000bc31');
INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash,created_at,expires_at)
VALUES ('30000000-0000-0000-0000-00000000bc30',decode(repeat('a1',32),'hex'),transaction_timestamp()-interval '2 hours',transaction_timestamp()+interval '22 hours');

DO $$
DECLARE
  v_outcome jsonb;
  v_before_session jsonb;
  v_after_session jsonb;
  v_before_media jsonb;
  v_after_media jsonb;
  v_before_authority jsonb;
  v_after_authority jsonb;
  v_before_idem bigint;
  v_after_idem bigint;
BEGIN
  SELECT to_jsonb(s) INTO v_before_session FROM public.async_session s WHERE async_session_id='20000000-0000-0000-0000-000000000230';
  SELECT jsonb_agg(to_jsonb(m) ORDER BY cut_position) INTO v_before_media FROM public.async_response_media m WHERE async_response_id='40000000-0000-0000-0000-00000000bc30';
  SELECT to_jsonb(a) INTO v_before_authority FROM public.responder_continuation_authority a WHERE session_participation_id='30000000-0000-0000-0000-00000000bc30';
  SELECT count(*) INTO v_before_idem FROM public.idempotency_record;

  v_outcome := public.hbd_continue_responding(
    '20000000-0000-0000-0000-000000000230','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('a1',32),'hex'));
  IF (SELECT count(*) FROM jsonb_object_keys(v_outcome)) <> 9
     OR NOT (v_outcome ?& ARRAY['async_session_id','responder_participation_id','state','resource_version','responding_started_at','responding_deadline_at','resolved_at','caller_is_active_editor','response_media']) THEN
    RAISE EXCEPTION 'continue outcome shape invalid: %',v_outcome;
  END IF;
  IF v_outcome->>'state'<>'RESPONDING' OR (v_outcome->>'resource_version')::bigint<>30 OR (v_outcome->>'caller_is_active_editor')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'continue active-browser projection invalid: %',v_outcome;
  END IF;
  IF v_outcome->'response_media' <> jsonb_build_array(jsonb_build_object('cut_position',1,'media_asset_id','50000000-0000-0000-0000-00000000bc31'::uuid)) THEN
    RAISE EXCEPTION 'continue B1 snapshot invalid: %',v_outcome->'response_media';
  END IF;

  v_outcome := public.hbd_continue_responding(
    '20000000-0000-0000-0000-000000000230','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc31',decode(repeat('a1',32),'hex'));
  IF (v_outcome->>'caller_is_active_editor')::boolean IS NOT FALSE OR (v_outcome->>'resource_version')::bigint<>30 THEN
    RAISE EXCEPTION 'continue secondary-browser projection invalid: %',v_outcome;
  END IF;

  SELECT to_jsonb(s) INTO v_after_session FROM public.async_session s WHERE async_session_id='20000000-0000-0000-0000-000000000230';
  SELECT jsonb_agg(to_jsonb(m) ORDER BY cut_position) INTO v_after_media FROM public.async_response_media m WHERE async_response_id='40000000-0000-0000-0000-00000000bc30';
  SELECT to_jsonb(a) INTO v_after_authority FROM public.responder_continuation_authority a WHERE session_participation_id='30000000-0000-0000-0000-00000000bc30';
  SELECT count(*) INTO v_after_idem FROM public.idempotency_record;
  IF v_before_session IS DISTINCT FROM v_after_session OR v_before_media IS DISTINCT FROM v_after_media OR v_before_authority IS DISTINCT FROM v_after_authority OR v_before_idem<>v_after_idem THEN
    RAISE EXCEPTION 'continuation read mutated canonical state';
  END IF;
END $$;

-- B2/B3/B4 prefix sessions prove ordered current composition.
DO $$
DECLARE n int; sid uuid; init_pid uuid; resp_pid uuid; rid uuid; token bytea; outcome jsonb; expected jsonb;
BEGIN
  FOR n IN 2..4 LOOP
    sid := ('20000000-0000-0000-0000-00000000023'||n)::uuid;
    init_pid := ('30000000-0000-0000-0000-00000000ac3'||n)::uuid;
    resp_pid := ('30000000-0000-0000-0000-00000000bc3'||n)::uuid;
    rid := ('40000000-0000-0000-0000-00000000bc3'||n)::uuid;
    token := decode(repeat(('a'||n)::text,32),'hex');
    INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES (sid,'RESPONDING',30+n);
    INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
      (init_pid,sid,'00000000-0000-0000-0000-00000000ac30','INITIATOR'),
      (resp_pid,sid,'00000000-0000-0000-0000-00000000bc30','RESPONDER');
    UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '3 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '2 hours',responding_deadline_at=transaction_timestamp()+interval '22 hours',current_editor_session_participation_id=resp_pid,active_editing_access_session_id='10000000-0000-0000-0000-00000000bc30' WHERE async_session_id=sid;
    INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES (rid,resp_pid);
    INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id)
      SELECT rid,g,('50000000-0000-0000-0000-00000000bc3'||g)::uuid FROM generate_series(1,n) g;
    INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash,created_at,expires_at)
      VALUES (resp_pid,token,transaction_timestamp()-interval '2 hours',transaction_timestamp()+interval '22 hours');
    outcome := public.hbd_continue_responding(sid,'00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc31',token);
    SELECT jsonb_agg(jsonb_build_object('cut_position',g,'media_asset_id',('50000000-0000-0000-0000-00000000bc3'||g)::uuid) ORDER BY g) INTO expected FROM generate_series(1,n) g;
    IF outcome->'response_media'<>expected OR (outcome->>'caller_is_active_editor')::boolean IS NOT FALSE THEN
      RAISE EXCEPTION 'continue B% snapshot invalid: %',n,outcome;
    END IF;
  END LOOP;
END $$;

-- Pre-B1: valid responder and capability exist, but no durable media checkpoint.
INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES ('20000000-0000-0000-0000-000000000235','RESPONDING',35);
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-00000000ac35','20000000-0000-0000-0000-000000000235','00000000-0000-0000-0000-00000000ac30','INITIATOR'),
('30000000-0000-0000-0000-00000000bc35','20000000-0000-0000-0000-000000000235','00000000-0000-0000-0000-00000000bc30','RESPONDER');
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '1 hour',responding_deadline_at=transaction_timestamp()+interval '23 hours',current_editor_session_participation_id='30000000-0000-0000-0000-00000000bc35',active_editing_access_session_id='10000000-0000-0000-0000-00000000bc30' WHERE async_session_id='20000000-0000-0000-0000-000000000235';
INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash,created_at,expires_at) VALUES ('30000000-0000-0000-0000-00000000bc35',decode(repeat('a5',32),'hex'),transaction_timestamp()-interval '1 hour',transaction_timestamp()+interval '23 hours');
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000235','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('a5',32),'hex'));
    RAISE EXCEPTION 'pre-B1 continuation unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='pre-B1 continuation unexpectedly accepted' THEN RAISE; END IF;
    IF position('continuation requires durable responder progress' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected pre-B1 error: %',SQLERRM; END IF;
  END;
END $$;

-- Security failures collapse to one generic continuation-authority error.
DO $$
DECLARE pas uuid; participant uuid; digest bytea;
BEGIN
  -- wrong token on otherwise valid responder
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000230','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('ff',32),'hex'));
    RAISE EXCEPTION 'wrong token unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='wrong token unexpectedly accepted' THEN RAISE; END IF;
    IF position('continuation authority invalid' in SQLERRM)=0 THEN RAISE EXCEPTION 'wrong-token oracle leak: %',SQLERRM; END IF;
  END;
  -- foreign participant and PAS with responder token
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000230','00000000-0000-0000-0000-00000000cc30','10000000-0000-0000-0000-00000000cc30',decode(repeat('a1',32),'hex'));
    RAISE EXCEPTION 'foreign participant unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='foreign participant unexpectedly accepted' THEN RAISE; END IF;
    IF position('continuation authority invalid' in SQLERRM)=0 THEN RAISE EXCEPTION 'foreign participant oracle leak: %',SQLERRM; END IF;
  END;
  FOREACH pas IN ARRAY ARRAY['10000000-0000-0000-0000-00000000bc32'::uuid,'10000000-0000-0000-0000-00000000bc33'::uuid] LOOP
    BEGIN
      PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000230','00000000-0000-0000-0000-00000000bc30',pas,decode(repeat('a1',32),'hex'));
      RAISE EXCEPTION 'invalid caller PAS unexpectedly accepted';
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM='invalid caller PAS unexpectedly accepted' THEN RAISE; END IF;
      IF position('continuation authority invalid' in SQLERRM)=0 THEN RAISE EXCEPTION 'caller PAS oracle leak: %',SQLERRM; END IF;
    END;
  END LOOP;
END $$;

-- Revoked authority is generic FORBIDDEN material; restore fixture afterward for isolation.
UPDATE public.responder_continuation_authority SET revoked_at=transaction_timestamp() WHERE session_participation_id='30000000-0000-0000-0000-00000000bc30';
DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000230','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('a1',32),'hex'));
    RAISE EXCEPTION 'revoked authority unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='revoked authority unexpectedly accepted' THEN RAISE; END IF;
    IF position('continuation authority invalid' in SQLERRM)=0 THEN RAISE EXCEPTION 'revoked authority oracle leak: %',SQLERRM; END IF;
  END;
END $$;
UPDATE public.responder_continuation_authority SET revoked_at=NULL WHERE session_participation_id='30000000-0000-0000-0000-00000000bc30';

-- Helper fixtures: early capability expiry, responding deadline expiry, WAITING, COMPLETED, sparse B state.
INSERT INTO public.async_session(async_session_id,state,resource_version) VALUES
('20000000-0000-0000-0000-000000000236','RESPONDING',36),
('20000000-0000-0000-0000-000000000237','RESPONDING',37),
('20000000-0000-0000-0000-000000000238','WAITING',38),
('20000000-0000-0000-0000-000000000239','COMPLETED',39),
('20000000-0000-0000-0000-000000000240','RESPONDING',40);

INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
('30000000-0000-0000-0000-00000000ac36','20000000-0000-0000-0000-000000000236','00000000-0000-0000-0000-00000000ac30','INITIATOR'),('30000000-0000-0000-0000-00000000bc36','20000000-0000-0000-0000-000000000236','00000000-0000-0000-0000-00000000bc30','RESPONDER'),
('30000000-0000-0000-0000-00000000ac37','20000000-0000-0000-0000-000000000237','00000000-0000-0000-0000-00000000ac30','INITIATOR'),('30000000-0000-0000-0000-00000000bc37','20000000-0000-0000-0000-000000000237','00000000-0000-0000-0000-00000000bc30','RESPONDER'),
('30000000-0000-0000-0000-00000000ac38','20000000-0000-0000-0000-000000000238','00000000-0000-0000-0000-00000000ac30','INITIATOR'),('30000000-0000-0000-0000-00000000bc38','20000000-0000-0000-0000-000000000238','00000000-0000-0000-0000-00000000bc30','RESPONDER'),
('30000000-0000-0000-0000-00000000ac39','20000000-0000-0000-0000-000000000239','00000000-0000-0000-0000-00000000ac30','INITIATOR'),('30000000-0000-0000-0000-00000000bc39','20000000-0000-0000-0000-000000000239','00000000-0000-0000-0000-00000000bc30','RESPONDER'),
('30000000-0000-0000-0000-00000000ac40','20000000-0000-0000-0000-000000000240','00000000-0000-0000-0000-00000000ac30','INITIATOR'),('30000000-0000-0000-0000-00000000bc40','20000000-0000-0000-0000-000000000240','00000000-0000-0000-0000-00000000bc30','RESPONDER');

UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '3 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '2 hours',responding_deadline_at=transaction_timestamp()+interval '22 hours',current_editor_session_participation_id='30000000-0000-0000-0000-00000000bc36',active_editing_access_session_id='10000000-0000-0000-0000-00000000bc30' WHERE async_session_id='20000000-0000-0000-0000-000000000236';
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '3 days',response_start_deadline_at=transaction_timestamp()-interval '2 days',responding_started_at=transaction_timestamp()-interval '25 hours',responding_deadline_at=transaction_timestamp()-interval '1 hour',current_editor_session_participation_id='30000000-0000-0000-0000-00000000bc37',active_editing_access_session_id='10000000-0000-0000-0000-00000000bc30' WHERE async_session_id='20000000-0000-0000-0000-000000000237';
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '2 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days' WHERE async_session_id='20000000-0000-0000-0000-000000000238';
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '2 days',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '3 hours',responding_deadline_at=transaction_timestamp()+interval '21 hours',completed_at=transaction_timestamp()-interval '1 hour' WHERE async_session_id='20000000-0000-0000-0000-000000000239';
UPDATE public.async_session SET invite_ready_at=transaction_timestamp()-interval '3 hours',response_start_deadline_at=transaction_timestamp()+interval '5 days',responding_started_at=transaction_timestamp()-interval '2 hours',responding_deadline_at=transaction_timestamp()+interval '22 hours',current_editor_session_participation_id='30000000-0000-0000-0000-00000000bc40',active_editing_access_session_id='10000000-0000-0000-0000-00000000bc30' WHERE async_session_id='20000000-0000-0000-0000-000000000240';

INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES
('40000000-0000-0000-0000-00000000bc36','30000000-0000-0000-0000-00000000bc36'),
('40000000-0000-0000-0000-00000000bc37','30000000-0000-0000-0000-00000000bc37'),
('40000000-0000-0000-0000-00000000bc40','30000000-0000-0000-0000-00000000bc40');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES
('40000000-0000-0000-0000-00000000bc36',1,'50000000-0000-0000-0000-00000000bc31'),
('40000000-0000-0000-0000-00000000bc37',1,'50000000-0000-0000-0000-00000000bc31'),
('40000000-0000-0000-0000-00000000bc40',1,'50000000-0000-0000-0000-00000000bc31'),
('40000000-0000-0000-0000-00000000bc40',3,'50000000-0000-0000-0000-00000000bc33');

INSERT INTO public.responder_continuation_authority(session_participation_id,token_hash,created_at,expires_at) VALUES
('30000000-0000-0000-0000-00000000bc36',decode(repeat('a6',32),'hex'),transaction_timestamp()-interval '2 hours',transaction_timestamp()-interval '1 hour'),
('30000000-0000-0000-0000-00000000bc37',decode(repeat('a7',32),'hex'),transaction_timestamp()-interval '25 hours',transaction_timestamp()+interval '1 hour'),
('30000000-0000-0000-0000-00000000bc40',decode(repeat('b0',32),'hex'),transaction_timestamp()-interval '2 hours',transaction_timestamp()+interval '22 hours');

DO $$ BEGIN
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000236','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('a6',32),'hex'));
    RAISE EXCEPTION 'expired continuation authority unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='expired continuation authority unexpectedly accepted' THEN RAISE; END IF;
    IF position('continuation authority invalid' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected authority-expiry error: %',SQLERRM; END IF;
  END;
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000237','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('a7',32),'hex'));
    RAISE EXCEPTION 'expired responding window unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='expired responding window unexpectedly accepted' THEN RAISE; END IF;
    IF position('responding window has expired' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected responding-deadline error: %',SQLERRM; END IF;
  END;
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000238','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('aa',32),'hex'));
    RAISE EXCEPTION 'WAITING continuation unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='WAITING continuation unexpectedly accepted' THEN RAISE; END IF;
    IF position('async session is not responding' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected WAITING error: %',SQLERRM; END IF;
  END;
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000239','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('aa',32),'hex'));
    RAISE EXCEPTION 'COMPLETED continuation unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='COMPLETED continuation unexpectedly accepted' THEN RAISE; END IF;
    IF position('async session is not responding' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected COMPLETED error: %',SQLERRM; END IF;
  END;
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000000240','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('b0',32),'hex'));
    RAISE EXCEPTION 'sparse continuation unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='sparse continuation unexpectedly accepted' THEN RAISE; END IF;
    IF position('responder response media prefix invariant violated' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected sparse error: %',SQLERRM; END IF;
  END;
  BEGIN
    PERFORM public.hbd_continue_responding('20000000-0000-0000-0000-000000009999','00000000-0000-0000-0000-00000000bc30','10000000-0000-0000-0000-00000000bc30',decode(repeat('aa',32),'hex'));
    RAISE EXCEPTION 'missing session continuation unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='missing session continuation unexpectedly accepted' THEN RAISE; END IF;
    IF position('async session not found' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected missing-session error: %',SQLERRM; END IF;
  END;
END $$;

ROLLBACK;
SELECT 'continue_responding_query_test PASS' AS result;
