DO $$
DECLARE
  table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['media_asset','personal_memory','personal_memory_media'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = table_name AND c.relrowsecurity
    ) THEN
      RAISE EXCEPTION '% must have RLS enabled', table_name;
    END IF;

    IF has_table_privilege('anon', 'public.' || table_name, 'SELECT,INSERT,UPDATE,DELETE') THEN
      RAISE EXCEPTION 'anon unexpectedly has DML on %', table_name;
    END IF;

    IF has_table_privilege('authenticated', 'public.' || table_name, 'SELECT,INSERT,UPDATE,DELETE') THEN
      RAISE EXCEPTION 'authenticated unexpectedly has DML on %', table_name;
    END IF;

    IF NOT has_table_privilege('service_role', 'public.' || table_name, 'SELECT,INSERT,UPDATE,DELETE') THEN
      RAISE EXCEPTION 'service_role missing backend DML on %', table_name;
    END IF;
  END LOOP;
END $$;

SELECT 'media_personal_access_test PASS' AS result;
