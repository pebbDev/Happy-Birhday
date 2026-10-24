BEGIN;
INSERT INTO public.participant(participant_id,display_name) VALUES
 ('13000000-0000-0000-0000-000000000001','A'),('13000000-0000-0000-0000-000000000002','B');
INSERT INTO public.media_asset(media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type) VALUES
 ('33000000-0000-0000-0000-000000000001','13000000-0000-0000-0000-000000000001','TENCENT_COS','canon/a1.jpg',decode(repeat('51',32),'hex'),'image/jpeg'),
 ('33000000-0000-0000-0000-000000000002','13000000-0000-0000-0000-000000000002','TENCENT_COS','canon/b1.jpg',decode(repeat('52',32),'hex'),'image/jpeg');
INSERT INTO public.async_session(async_session_id,state,completed_at) VALUES ('43000000-0000-0000-0000-000000000001','COMPLETED',now());
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
 ('53000000-0000-0000-0000-000000000001','43000000-0000-0000-0000-000000000001','13000000-0000-0000-0000-000000000001','INITIATOR'),
 ('53000000-0000-0000-0000-000000000002','43000000-0000-0000-0000-000000000001','13000000-0000-0000-0000-000000000002','RESPONDER');
INSERT INTO public.canonical_memory(canonical_memory_id,async_session_id) VALUES ('83000000-0000-0000-0000-000000000001','43000000-0000-0000-0000-000000000001');
INSERT INTO public.canonical_memory_media(canonical_memory_id,session_participation_id,cut_position,media_asset_id) VALUES
 ('83000000-0000-0000-0000-000000000001','53000000-0000-0000-0000-000000000001',1,'33000000-0000-0000-0000-000000000001'),
 ('83000000-0000-0000-0000-000000000001','53000000-0000-0000-0000-000000000002',1,'33000000-0000-0000-0000-000000000002');
DO $$ BEGIN
  BEGIN INSERT INTO public.canonical_memory_media(canonical_memory_id,session_participation_id,cut_position,media_asset_id) VALUES ('83000000-0000-0000-0000-000000000001','53000000-0000-0000-0000-000000000001',5,'33000000-0000-0000-0000-000000000002'); RAISE EXCEPTION 'canonical cut 5 accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN DELETE FROM public.session_participation WHERE session_participation_id='53000000-0000-0000-0000-000000000001'; RAISE EXCEPTION 'canonical participation delete accepted'; EXCEPTION WHEN foreign_key_violation THEN NULL; END;
  BEGIN DELETE FROM public.media_asset WHERE media_asset_id='33000000-0000-0000-0000-000000000001'; RAISE EXCEPTION 'canonical media delete accepted'; EXCEPTION WHEN foreign_key_violation THEN NULL; END;
END $$;
ROLLBACK;
SELECT 'async_canonical_constraints_test PASS' AS result;
