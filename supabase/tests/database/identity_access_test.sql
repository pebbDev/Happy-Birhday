\set ON_ERROR_STOP on

DO $$
DECLARE
  tbl text;
  rls_enabled boolean;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['participant','participant_access_capability','protected_access_session','protected_entry_policy','pre_resolution_access_grant'] LOOP
    IF has_table_privilege('anon', 'public.' || tbl, 'SELECT')
       OR has_table_privilege('anon', 'public.' || tbl, 'INSERT')
       OR has_table_privilege('anon', 'public.' || tbl, 'UPDATE')
       OR has_table_privilege('anon', 'public.' || tbl, 'DELETE') THEN
      RAISE EXCEPTION 'anon unexpectedly has DML privilege on %', tbl;
    END IF;

    IF has_table_privilege('authenticated', 'public.' || tbl, 'SELECT')
       OR has_table_privilege('authenticated', 'public.' || tbl, 'INSERT')
       OR has_table_privilege('authenticated', 'public.' || tbl, 'UPDATE')
       OR has_table_privilege('authenticated', 'public.' || tbl, 'DELETE') THEN
      RAISE EXCEPTION 'authenticated unexpectedly has DML privilege on %', tbl;
    END IF;

    IF NOT has_table_privilege('service_role', 'public.' || tbl, 'SELECT')
       OR NOT has_table_privilege('service_role', 'public.' || tbl, 'INSERT')
       OR NOT has_table_privilege('service_role', 'public.' || tbl, 'UPDATE')
       OR NOT has_table_privilege('service_role', 'public.' || tbl, 'DELETE') THEN
      RAISE EXCEPTION 'service_role missing required DML privilege on %', tbl;
    END IF;

    SELECT c.relrowsecurity INTO rls_enabled
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname=tbl;
    IF rls_enabled IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'RLS must be enabled on %', tbl;
    END IF;
  END LOOP;
END $$;

SELECT 'identity_access_test PASS' AS result;

