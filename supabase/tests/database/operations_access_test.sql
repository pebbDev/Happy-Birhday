DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE oid='public.idempotency_record'::regclass AND relrowsecurity) THEN
    RAISE EXCEPTION 'idempotency_record must have RLS enabled';
  END IF;

  IF has_table_privilege('anon','public.idempotency_record','SELECT') OR has_table_privilege('anon','public.idempotency_record','INSERT') THEN
    RAISE EXCEPTION 'anon unexpectedly has idempotency_record DML';
  END IF;
  IF has_table_privilege('authenticated','public.idempotency_record','SELECT') OR has_table_privilege('authenticated','public.idempotency_record','INSERT') THEN
    RAISE EXCEPTION 'authenticated unexpectedly has idempotency_record DML';
  END IF;
  IF NOT has_table_privilege('service_role','public.idempotency_record','SELECT') OR NOT has_table_privilege('service_role','public.idempotency_record','INSERT') THEN
    RAISE EXCEPTION 'service_role missing idempotency_record backend DML';
  END IF;

  IF has_function_privilege('anon','public.hbd_enter_protected_experience(uuid,bytea,bigint,text,bytea,text,text)','EXECUTE') THEN RAISE EXCEPTION 'anon unexpectedly can execute hbd_enter_protected_experience'; END IF;
  IF has_function_privilege('authenticated','public.hbd_enter_protected_experience(uuid,bytea,bigint,text,bytea,text,text)','EXECUTE') THEN RAISE EXCEPTION 'authenticated unexpectedly can execute hbd_enter_protected_experience'; END IF;
  IF NOT has_function_privilege('service_role','public.hbd_enter_protected_experience(uuid,bytea,bigint,text,bytea,text,text)','EXECUTE') THEN RAISE EXCEPTION 'service_role cannot execute hbd_enter_protected_experience'; END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) acl
    WHERE p.oid=to_regprocedure('public.hbd_enter_protected_experience(uuid,bytea,bigint,text,bytea,text,text)')
      AND acl.grantee=0 AND acl.privilege_type='EXECUTE'
  ) THEN RAISE EXCEPTION 'PUBLIC unexpectedly can execute hbd_enter_protected_experience'; END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p WHERE p.oid=to_regprocedure('public.hbd_enter_protected_experience(uuid,bytea,bigint,text,bytea,text,text)') AND p.prosecdef) THEN
    RAISE EXCEPTION 'hbd_enter_protected_experience must remain SECURITY INVOKER';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc p WHERE p.oid=to_regprocedure('public.hbd_enter_protected_experience(uuid,bytea,bigint,text,bytea,text,text)') AND p.proconfig @> ARRAY['search_path=""']::text[]) THEN
    RAISE EXCEPTION 'hbd_enter_protected_experience search_path is not hardened';
  END IF;  IF has_function_privilege('anon','public.hbd_create_async_session(uuid,uuid,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly can execute hbd_create_async_session';
  END IF;
  IF has_function_privilege('authenticated','public.hbd_create_async_session(uuid,uuid,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'authenticated unexpectedly can execute hbd_create_async_session';
  END IF;
  IF NOT has_function_privilege('service_role','public.hbd_create_async_session(uuid,uuid,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role cannot execute hbd_create_async_session';
  END IF;
  IF has_function_privilege('anon','public.hbd_mark_async_invite_ready(uuid,uuid,uuid,bigint,uuid[],text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly can execute hbd_mark_async_invite_ready';
  END IF;
  IF has_function_privilege('authenticated','public.hbd_mark_async_invite_ready(uuid,uuid,uuid,bigint,uuid[],text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'authenticated unexpectedly can execute hbd_mark_async_invite_ready';
  END IF;
  IF NOT has_function_privilege('service_role','public.hbd_mark_async_invite_ready(uuid,uuid,uuid,bigint,uuid[],text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role cannot execute hbd_mark_async_invite_ready';
  END IF;
  IF has_function_privilege('anon','public.hbd_save_async_response_cut(uuid,uuid,uuid,smallint,uuid,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly can execute hbd_save_async_response_cut';
  END IF;
  IF has_function_privilege('authenticated','public.hbd_save_async_response_cut(uuid,uuid,uuid,smallint,uuid,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'authenticated unexpectedly can execute hbd_save_async_response_cut';
  END IF;
  IF NOT has_function_privilege('service_role','public.hbd_save_async_response_cut(uuid,uuid,uuid,smallint,uuid,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role cannot execute hbd_save_async_response_cut';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) acl
    WHERE p.oid=to_regprocedure('public.hbd_save_async_response_cut(uuid,uuid,uuid,smallint,uuid,bigint,text,bytea)')
      AND acl.grantee=0 AND acl.privilege_type='EXECUTE'
  ) THEN
    RAISE EXCEPTION 'PUBLIC unexpectedly can execute hbd_save_async_response_cut';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.oid=to_regprocedure('public.hbd_save_async_response_cut(uuid,uuid,uuid,smallint,uuid,bigint,text,bytea)')
      AND p.prosecdef
  ) THEN
    RAISE EXCEPTION 'hbd_save_async_response_cut must remain SECURITY INVOKER';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.oid=to_regprocedure('public.hbd_save_async_response_cut(uuid,uuid,uuid,smallint,uuid,bigint,text,bytea)')
      AND p.proconfig @> ARRAY['search_path=""']::text[]
  ) THEN
    RAISE EXCEPTION 'hbd_save_async_response_cut search_path is not hardened';
  END IF;
  IF has_function_privilege('anon','public.hbd_take_over_editing(uuid,uuid,uuid,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly can execute hbd_take_over_editing';
  END IF;
  IF has_function_privilege('authenticated','public.hbd_take_over_editing(uuid,uuid,uuid,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'authenticated unexpectedly can execute hbd_take_over_editing';
  END IF;
  IF NOT has_function_privilege('service_role','public.hbd_take_over_editing(uuid,uuid,uuid,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role cannot execute hbd_take_over_editing';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) acl
    WHERE p.oid=to_regprocedure('public.hbd_take_over_editing(uuid,uuid,uuid,bigint,text,bytea)')
      AND acl.grantee=0 AND acl.privilege_type='EXECUTE'
  ) THEN RAISE EXCEPTION 'PUBLIC unexpectedly can execute hbd_take_over_editing'; END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.oid=to_regprocedure('public.hbd_take_over_editing(uuid,uuid,uuid,bigint,text,bytea)') AND p.prosecdef
  ) THEN RAISE EXCEPTION 'hbd_take_over_editing must remain SECURITY INVOKER'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.oid=to_regprocedure('public.hbd_take_over_editing(uuid,uuid,uuid,bigint,text,bytea)')
      AND p.proconfig @> ARRAY['search_path=""']::text[]
  ) THEN RAISE EXCEPTION 'hbd_take_over_editing search_path is not hardened'; END IF;
  IF has_function_privilege('anon','public.hbd_continue_responding(uuid,uuid,uuid,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly can execute hbd_continue_responding';
  END IF;
  IF has_function_privilege('authenticated','public.hbd_continue_responding(uuid,uuid,uuid,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'authenticated unexpectedly can execute hbd_continue_responding';
  END IF;
  IF NOT has_function_privilege('service_role','public.hbd_continue_responding(uuid,uuid,uuid,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role cannot execute hbd_continue_responding';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) acl
    WHERE p.oid=to_regprocedure('public.hbd_continue_responding(uuid,uuid,uuid,bytea)')
      AND acl.grantee=0 AND acl.privilege_type='EXECUTE'
  ) THEN RAISE EXCEPTION 'PUBLIC unexpectedly can execute hbd_continue_responding'; END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.oid=to_regprocedure('public.hbd_continue_responding(uuid,uuid,uuid,bytea)') AND p.prosecdef
  ) THEN RAISE EXCEPTION 'hbd_continue_responding must remain SECURITY INVOKER'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.oid=to_regprocedure('public.hbd_continue_responding(uuid,uuid,uuid,bytea)')
      AND p.provolatile='s'
      AND p.proconfig @> ARRAY['search_path=""']::text[]
  ) THEN RAISE EXCEPTION 'hbd_continue_responding must be STABLE with hardened search_path'; END IF;
  IF has_function_privilege('anon','public.hbd_start_responding(uuid,uuid,uuid,bytea,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'anon unexpectedly can execute hbd_start_responding';
  END IF;
  IF has_function_privilege('authenticated','public.hbd_complete_async_session(uuid,uuid,uuid,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'authenticated unexpectedly can execute hbd_complete_async_session';
  END IF;
  IF NOT has_function_privilege('service_role','public.hbd_release_claim(uuid,uuid,uuid,bigint,text,bytea)','EXECUTE') THEN
    RAISE EXCEPTION 'service_role cannot execute hbd_release_claim';
  END IF;
END $$;
SELECT 'operations_access_test PASS' AS result;

