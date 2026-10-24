DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['async_session','session_participation','async_response','async_response_media','responder_continuation_authority','canonical_memory','canonical_memory_media'] LOOP
    IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid=to_regclass('public.'||t)) THEN RAISE EXCEPTION '% must have RLS enabled', t; END IF;
    IF has_table_privilege('anon','public.'||t,'SELECT,INSERT,UPDATE,DELETE') THEN RAISE EXCEPTION 'anon DML leaked on %', t; END IF;
    IF has_table_privilege('authenticated','public.'||t,'SELECT,INSERT,UPDATE,DELETE') THEN RAISE EXCEPTION 'authenticated DML leaked on %', t; END IF;
    IF NOT has_table_privilege('service_role','public.'||t,'SELECT,INSERT,UPDATE,DELETE') THEN RAISE EXCEPTION 'service_role DML missing on %', t; END IF;
  END LOOP;
END $$;
SELECT 'async_access_test PASS' AS result;
