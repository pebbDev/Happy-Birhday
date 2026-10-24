DO $$
BEGIN
  IF to_regclass('public.media_asset') IS NULL THEN
    RAISE EXCEPTION 'media_asset table missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'media_asset'
      AND column_name = 'sha256_digest' AND data_type = 'bytea'
  ) THEN
    RAISE EXCEPTION 'media_asset.sha256_digest bytea missing';
  END IF;
END $$;

SELECT 'media_schema_test PASS' AS result;
