BEGIN;

INSERT INTO public.participant(participant_id, display_name)
VALUES ('00000000-0000-0000-0000-000000000401', 'Memory Tester');

INSERT INTO public.media_asset(media_asset_id, uploaded_by_participant_id, storage_provider, object_key, sha256_digest, mime_type)
VALUES
  ('00000000-0000-0000-0000-000000000411', '00000000-0000-0000-0000-000000000401', 'TENCENT_COS', 'tests/m1.jpg', decode(repeat('11', 32), 'hex'), 'image/jpeg'),
  ('00000000-0000-0000-0000-000000000412', '00000000-0000-0000-0000-000000000401', 'TENCENT_COS', 'tests/m2.jpg', decode(repeat('22', 32), 'hex'), 'image/jpeg'),
  ('00000000-0000-0000-0000-000000000413', '00000000-0000-0000-0000-000000000401', 'TENCENT_COS', 'tests/m3.jpg', decode(repeat('33', 32), 'hex'), 'image/jpeg'),
  ('00000000-0000-0000-0000-000000000414', '00000000-0000-0000-0000-000000000401', 'TENCENT_COS', 'tests/m4.jpg', decode(repeat('44', 32), 'hex'), 'image/jpeg');

INSERT INTO public.personal_memory(
  personal_memory_id, participant_id, composition_version, composition_jsonb
) VALUES (
  '00000000-0000-0000-0000-000000000421',
  '00000000-0000-0000-0000-000000000401',
  1,
  '{"version":1}'::jsonb
);

INSERT INTO public.personal_memory_media(personal_memory_id, cut_position, media_asset_id)
VALUES
  ('00000000-0000-0000-0000-000000000421', 1, '00000000-0000-0000-0000-000000000411'),
  ('00000000-0000-0000-0000-000000000421', 2, '00000000-0000-0000-0000-000000000412'),
  ('00000000-0000-0000-0000-000000000421', 3, '00000000-0000-0000-0000-000000000413'),
  ('00000000-0000-0000-0000-000000000421', 4, '00000000-0000-0000-0000-000000000414');

DO $$
BEGIN
  BEGIN
    INSERT INTO public.personal_memory_media(personal_memory_id, cut_position, media_asset_id)
    VALUES ('00000000-0000-0000-0000-000000000421', 5, '00000000-0000-0000-0000-000000000411');
    RAISE EXCEPTION 'cut_position 5 was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO public.personal_memory_media(personal_memory_id, cut_position, media_asset_id)
    VALUES ('00000000-0000-0000-0000-000000000421', 1, '00000000-0000-0000-0000-000000000414');
    RAISE EXCEPTION 'duplicate cut slot was accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO public.personal_memory_media(personal_memory_id, cut_position, media_asset_id)
    VALUES ('00000000-0000-0000-0000-000000000421', 3, '00000000-0000-0000-0000-000000000411');
    RAISE EXCEPTION 'duplicate media asset was accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO public.personal_memory(participant_id, composition_version, composition_jsonb)
    VALUES ('00000000-0000-0000-0000-000000000401', 0, '{"version":0}'::jsonb);
    RAISE EXCEPTION 'composition_version 0 was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

ROLLBACK;
SELECT 'personal_memory_constraints_test PASS' AS result;
