BEGIN;

INSERT INTO public.idempotency_record(command_scope,idempotency_key,request_hash,outcome_jsonb)
VALUES ('ASYNC_START_RESPONDING','idem-1',decode(repeat('aa',32),'hex'),'{}'::jsonb);

DO $$
BEGIN
  BEGIN
    INSERT INTO public.idempotency_record(command_scope,idempotency_key,request_hash,outcome_jsonb)
    VALUES ('ASYNC_START_RESPONDING','idem-1',decode(repeat('bb',32),'hex'),'{}'::jsonb);
    RAISE EXCEPTION 'duplicate scope+key unexpectedly accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO public.idempotency_record(command_scope,idempotency_key,request_hash,outcome_jsonb)
    VALUES ('ASYNC_RELEASE_CLAIM','idem-short',decode('abcd','hex'),'{}'::jsonb);
    RAISE EXCEPTION 'short request hash unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO public.idempotency_record(command_scope,idempotency_key,request_hash,outcome_jsonb)
    VALUES ('','idem-empty-scope',decode(repeat('cc',32),'hex'),'{}'::jsonb);
    RAISE EXCEPTION 'blank command_scope unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

ROLLBACK;
SELECT 'idempotency_constraints_test PASS' AS result;
