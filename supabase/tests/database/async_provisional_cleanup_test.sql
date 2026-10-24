BEGIN;
INSERT INTO public.participant(participant_id,display_name) VALUES ('12000000-0000-0000-0000-000000000001','B');
INSERT INTO public.media_asset(media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type) VALUES ('32000000-0000-0000-0000-000000000001','12000000-0000-0000-0000-000000000001','TENCENT_COS','cleanup/b1.jpg',decode(repeat('44',32),'hex'),'image/jpeg');
INSERT INTO public.async_session(async_session_id,state) VALUES ('42000000-0000-0000-0000-000000000001','WAITING');
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES ('52000000-0000-0000-0000-000000000001','42000000-0000-0000-0000-000000000001','12000000-0000-0000-0000-000000000001','RESPONDER');
INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES ('62000000-0000-0000-0000-000000000001','52000000-0000-0000-0000-000000000001');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES ('62000000-0000-0000-0000-000000000001',1,'32000000-0000-0000-0000-000000000001');
INSERT INTO public.responder_continuation_authority(continuation_authority_id,session_participation_id,token_hash) VALUES ('72000000-0000-0000-0000-000000000001','52000000-0000-0000-0000-000000000001',decode(repeat('72',32),'hex'));
DELETE FROM public.session_participation WHERE session_participation_id='52000000-0000-0000-0000-000000000001';
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM public.async_response WHERE session_participation_id='52000000-0000-0000-0000-000000000001') THEN RAISE EXCEPTION 'response not cascaded'; END IF;
 IF EXISTS (SELECT 1 FROM public.responder_continuation_authority WHERE session_participation_id='52000000-0000-0000-0000-000000000001') THEN RAISE EXCEPTION 'continuation not cascaded'; END IF;
 IF EXISTS (SELECT 1 FROM public.async_response_media WHERE async_response_id='62000000-0000-0000-0000-000000000001') THEN RAISE EXCEPTION 'response media not cascaded'; END IF;
END $$;
ROLLBACK;
SELECT 'async_provisional_cleanup_test PASS' AS result;
