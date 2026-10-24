BEGIN;

INSERT INTO public.participant(participant_id, display_name)
VALUES ('00000000-0000-0000-0000-000000000301', 'Media Tester');

INSERT INTO public.media_asset(
  media_asset_id, uploaded_by_participant_id, storage_provider, object_key, sha256_digest, mime_type
) VALUES (
  '00000000-0000-0000-0000-000000000311',
  '00000000-0000-0000-0000-000000000301',
  'TENCENT_COS', 'tests/media-1.jpg', decode(repeat('ab', 32), 'hex'), 'image/jpeg'
);

DO $$
BEGIN
  BEGIN
    INSERT INTO public.media_asset(uploaded_by_participant_id, storage_provider, object_key, sha256_digest, mime_type)
    VALUES ('00000000-0000-0000-0000-000000000301', 'TENCENT_COS', 'tests/bad-hash.jpg', decode('abcd', 'hex'), 'image/jpeg');
    RAISE EXCEPTION 'short digest was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO public.media_asset(uploaded_by_participant_id, storage_provider, object_key, sha256_digest, mime_type)
    VALUES ('00000000-0000-0000-0000-000000000301', 'OTHER', 'tests/provider.jpg', decode(repeat('cd', 32), 'hex'), 'image/jpeg');
    RAISE EXCEPTION 'invalid provider was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO public.media_asset(uploaded_by_participant_id, storage_provider, object_key, sha256_digest, mime_type)
    VALUES ('00000000-0000-0000-0000-000000000301', 'TENCENT_COS', 'tests/media-1.jpg', decode(repeat('ef', 32), 'hex'), 'image/png');
    RAISE EXCEPTION 'duplicate object identity was accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
END $$;

ROLLBACK;
SELECT 'media_constraints_test PASS' AS result;
