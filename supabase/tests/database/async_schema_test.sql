DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'async_session','session_participation','async_response','async_response_media',
    'responder_continuation_authority','canonical_memory','canonical_memory_media'
  ] LOOP
    IF to_regclass('public.' || t) IS NULL THEN RAISE EXCEPTION '% table missing', t; END IF;
  END LOOP;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint c JOIN pg_class r ON r.oid=c.conrelid
    WHERE r.relname='session_participation' AND c.conname='uq_session_participation_role'
  ) THEN RAISE EXCEPTION 'session role uniqueness missing'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint c JOIN pg_class r ON r.oid=c.conrelid
    WHERE r.relname='canonical_memory' AND c.conname='uq_canonical_memory_session'
  ) THEN RAISE EXCEPTION 'canonical memory/session uniqueness missing'; END IF;
END $$;
SELECT 'async_schema_test PASS' AS result;
