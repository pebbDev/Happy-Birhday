DO $$
BEGIN
  IF to_regclass('public.personal_memory') IS NULL THEN
    RAISE EXCEPTION 'personal_memory table missing';
  END IF;

  IF to_regclass('public.personal_memory_media') IS NULL THEN
    RAISE EXCEPTION 'personal_memory_media table missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'personal_memory'
      AND column_name = 'composition_jsonb' AND data_type = 'jsonb'
  ) THEN
    RAISE EXCEPTION 'personal_memory.composition_jsonb jsonb missing';
  END IF;
END $$;

SELECT 'personal_memory_schema_test PASS' AS result;
