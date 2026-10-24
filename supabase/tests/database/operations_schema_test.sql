DO $$
BEGIN
  IF to_regclass('public.idempotency_record') IS NULL THEN
    RAISE EXCEPTION 'idempotency_record table missing';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='idempotency_record'
      AND column_name='request_hash' AND data_type='bytea'
  ) THEN
    RAISE EXCEPTION 'idempotency_record.request_hash bytea missing';
  END IF;
  IF to_regprocedure('public.hbd_enter_protected_experience(uuid,bytea,bigint,text,bytea,text,text)') IS NULL THEN
    RAISE EXCEPTION 'hbd_enter_protected_experience function missing';
  END IF;
  IF pg_get_function_result(to_regprocedure('public.hbd_enter_protected_experience(uuid,bytea,bigint,text,bytea,text,text)')) <> 'jsonb' THEN
    RAISE EXCEPTION 'hbd_enter_protected_experience must return jsonb';
  END IF;  IF to_regprocedure('public.hbd_create_async_session(uuid,uuid,text,bytea)') IS NULL THEN
    RAISE EXCEPTION 'hbd_create_async_session function missing';
  END IF;
  IF to_regprocedure('public.hbd_mark_async_invite_ready(uuid,uuid,uuid,bigint,uuid[],text,bytea)') IS NULL THEN
    RAISE EXCEPTION 'hbd_mark_async_invite_ready function missing';
  END IF;
  IF to_regprocedure('public.hbd_save_async_response_cut(uuid,uuid,uuid,smallint,uuid,bigint,text,bytea)') IS NULL THEN
    RAISE EXCEPTION 'hbd_save_async_response_cut function missing';
  END IF;
  IF pg_get_function_result(to_regprocedure('public.hbd_save_async_response_cut(uuid,uuid,uuid,smallint,uuid,bigint,text,bytea)')) <> 'jsonb' THEN
    RAISE EXCEPTION 'hbd_save_async_response_cut must return jsonb';
  END IF;
  IF to_regprocedure('public.hbd_take_over_editing(uuid,uuid,uuid,bigint,text,bytea)') IS NULL THEN
    RAISE EXCEPTION 'hbd_take_over_editing function missing';
  END IF;
  IF pg_get_function_result(to_regprocedure('public.hbd_take_over_editing(uuid,uuid,uuid,bigint,text,bytea)')) <> 'jsonb' THEN
    RAISE EXCEPTION 'hbd_take_over_editing must return jsonb';
  END IF;
  IF to_regprocedure('public.hbd_continue_responding(uuid,uuid,uuid,bytea)') IS NULL THEN
    RAISE EXCEPTION 'hbd_continue_responding function missing';
  END IF;
  IF pg_get_function_result(to_regprocedure('public.hbd_continue_responding(uuid,uuid,uuid,bytea)')) <> 'jsonb' THEN
    RAISE EXCEPTION 'hbd_continue_responding must return jsonb';
  END IF;
  IF to_regprocedure('public.hbd_start_responding(uuid,uuid,uuid,bytea,bigint,text,bytea)') IS NULL THEN
    RAISE EXCEPTION 'hbd_start_responding function missing';
  END IF;
  IF to_regprocedure('public.hbd_release_claim(uuid,uuid,uuid,bigint,text,bytea)') IS NULL THEN
    RAISE EXCEPTION 'hbd_release_claim function missing';
  END IF;
  IF to_regprocedure('public.hbd_complete_async_session(uuid,uuid,uuid,bigint,text,bytea)') IS NULL THEN
    RAISE EXCEPTION 'hbd_complete_async_session function missing';
  END IF;
END $$;
SELECT 'operations_schema_test PASS' AS result;

