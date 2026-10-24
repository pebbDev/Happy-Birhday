\set ON_ERROR_STOP on

DO $$
BEGIN
  IF to_regclass('public.participant') IS NULL THEN
    RAISE EXCEPTION 'participant table missing';
  END IF;
  IF to_regclass('public.participant_access_capability') IS NULL THEN
    RAISE EXCEPTION 'participant_access_capability table missing';
  END IF;
  IF to_regclass('public.protected_access_session') IS NULL THEN
    RAISE EXCEPTION 'protected_access_session table missing';
  END IF;
END $$;

DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'participant_access_capability'
    AND column_name IN ('capability_type','token_hash','expires_at','consumed_at','revoked_at');
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'participant_access_capability required columns missing';
  END IF;

  SELECT count(*) INTO v_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'protected_access_session'
    AND column_name IN ('participant_id','session_token_hash','expires_at','revoked_at');
  IF v_count <> 4 THEN
    RAISE EXCEPTION 'protected_access_session required columns missing';
  END IF;
END $$;

DO $$
DECLARE
  v_type text;
BEGIN
  SELECT data_type INTO v_type
  FROM information_schema.columns
  WHERE table_schema='public'
    AND table_name='participant_access_capability'
    AND column_name='token_hash';
  IF v_type <> 'bytea' THEN
    RAISE EXCEPTION 'participant_access_capability.token_hash must be bytea, got %', v_type;
  END IF;

  SELECT data_type INTO v_type
  FROM information_schema.columns
  WHERE table_schema='public'
    AND table_name='protected_access_session'
    AND column_name='session_token_hash';
  IF v_type <> 'bytea' THEN
    RAISE EXCEPTION 'protected_access_session.session_token_hash must be bytea, got %', v_type;
  END IF;
END $$;

DO $$
DECLARE v_count integer;
BEGIN
  IF to_regclass('public.protected_entry_policy') IS NULL THEN RAISE EXCEPTION 'protected_entry_policy table missing'; END IF;
  IF to_regclass('public.pre_resolution_access_grant') IS NULL THEN RAISE EXCEPTION 'pre_resolution_access_grant table missing'; END IF;

  SELECT count(*) INTO v_count FROM information_schema.columns
  WHERE table_schema='public' AND table_name='protected_entry_policy'
    AND column_name IN ('protected_entry_policy_id','generation','verifier_scheme','pin_hash','pin_salt','argon2_memory_kib','argon2_iterations','argon2_parallelism','enabled','created_at','rotated_at');
  IF v_count <> 11 THEN RAISE EXCEPTION 'protected_entry_policy required columns missing'; END IF;

  SELECT count(*) INTO v_count FROM information_schema.columns
  WHERE table_schema='public' AND table_name='pre_resolution_access_grant'
    AND column_name IN ('pre_resolution_access_grant_id','credential_hash','created_at','expires_at','consumed_at','revoked_at');
  IF v_count <> 6 THEN RAISE EXCEPTION 'pre_resolution_access_grant required columns missing'; END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='pre_resolution_access_grant' AND column_name IN ('participant_id','role','resource_version','destination')) THEN
    RAISE EXCEPTION 'pre_resolution_access_grant contains forbidden authority/application columns';
  END IF;

  IF (SELECT data_type FROM information_schema.columns WHERE table_schema='public' AND table_name='protected_entry_policy' AND column_name='pin_hash') <> 'bytea'
     OR (SELECT data_type FROM information_schema.columns WHERE table_schema='public' AND table_name='protected_entry_policy' AND column_name='pin_salt') <> 'bytea'
     OR (SELECT data_type FROM information_schema.columns WHERE table_schema='public' AND table_name='pre_resolution_access_grant' AND column_name='credential_hash') <> 'bytea' THEN
    RAISE EXCEPTION 'protected-entry verifier columns must be bytea';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.protected_entry_policy'::regclass AND contype='u' AND pg_get_constraintdef(oid) LIKE 'UNIQUE (generation)%') THEN
    RAISE EXCEPTION 'protected_entry_policy generation unique constraint missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.pre_resolution_access_grant'::regclass AND contype='u' AND pg_get_constraintdef(oid) LIKE 'UNIQUE (credential_hash)%') THEN
    RAISE EXCEPTION 'pre_resolution_access_grant credential_hash unique constraint missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='protected_entry_policy' AND indexdef ILIKE '%UNIQUE%' AND indexdef ILIKE '%WHERE (enabled = true)%') THEN
    RAISE EXCEPTION 'protected_entry_policy one-enabled partial unique index missing';
  END IF;
END $$;
SELECT 'identity_schema_test PASS' AS result;

