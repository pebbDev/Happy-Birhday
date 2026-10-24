BEGIN;
INSERT INTO public.participant(participant_id,display_name) VALUES
 ('10000000-0000-0000-0000-000000000001','A'),
 ('10000000-0000-0000-0000-000000000002','B'),
 ('10000000-0000-0000-0000-000000000003','C');
INSERT INTO public.protected_access_session(protected_access_session_id,participant_id,session_token_hash,expires_at) VALUES
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',decode(repeat('11',32),'hex'),now()+interval '1 day'),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002',decode(repeat('22',32),'hex'),now()+interval '1 day');
INSERT INTO public.media_asset(media_asset_id,uploaded_by_participant_id,storage_provider,object_key,sha256_digest,mime_type) VALUES
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','TENCENT_COS','a/1.jpg',decode(repeat('31',32),'hex'),'image/jpeg'),
 ('30000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','TENCENT_COS','b/1.jpg',decode(repeat('32',32),'hex'),'image/jpeg');

INSERT INTO public.async_session(async_session_id,state) VALUES ('40000000-0000-0000-0000-000000000001','INITIATING');
INSERT INTO public.session_participation(session_participation_id,async_session_id,participant_id,role) VALUES
 ('50000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','INITIATOR'),
 ('50000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','RESPONDER');

DO $$ BEGIN
  BEGIN INSERT INTO public.session_participation(async_session_id,participant_id,role) VALUES ('40000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003','RESPONDER'); RAISE EXCEPTION 'duplicate responder accepted';
  EXCEPTION WHEN unique_violation THEN NULL; END;
  BEGIN INSERT INTO public.async_session(state) VALUES ('BOGUS'); RAISE EXCEPTION 'invalid state accepted';
  EXCEPTION WHEN check_violation THEN NULL; END;
END $$;

INSERT INTO public.async_response(async_response_id,session_participation_id) VALUES ('60000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000002');
INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES ('60000000-0000-0000-0000-000000000001',1,'30000000-0000-0000-0000-000000000002');
DO $$ BEGIN
  BEGIN INSERT INTO public.async_response(session_participation_id) VALUES ('50000000-0000-0000-0000-000000000002'); RAISE EXCEPTION 'second response accepted';
  EXCEPTION WHEN unique_violation THEN NULL; END;
  BEGIN INSERT INTO public.async_response_media(async_response_id,cut_position,media_asset_id) VALUES ('60000000-0000-0000-0000-000000000001',5,'30000000-0000-0000-0000-000000000001'); RAISE EXCEPTION 'cut 5 accepted';
  EXCEPTION WHEN check_violation THEN NULL; END;
END $$;

INSERT INTO public.responder_continuation_authority(continuation_authority_id,session_participation_id,token_hash) VALUES ('70000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000002',decode(repeat('71',32),'hex'));
INSERT INTO public.canonical_memory(canonical_memory_id,async_session_id) VALUES ('80000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001');
DO $$ BEGIN
  BEGIN INSERT INTO public.canonical_memory(async_session_id) VALUES ('40000000-0000-0000-0000-000000000001'); RAISE EXCEPTION 'second canonical memory accepted';
  EXCEPTION WHEN unique_violation THEN NULL; END;
END $$;
ROLLBACK;
SELECT 'async_constraints_test PASS' AS result;
