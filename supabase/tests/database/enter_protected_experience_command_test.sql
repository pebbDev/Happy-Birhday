\set ON_ERROR_STOP on
BEGIN;

DO $$
DECLARE v_count bigint;
BEGIN
  SELECT count(*) INTO v_count FROM public.protected_entry_policy;
  IF v_count <> 0 THEN RAISE EXCEPTION 'fresh migration must not seed protected entry policy'; END IF;
END $$;

INSERT INTO public.protected_entry_policy(
  protected_entry_policy_id,generation,verifier_scheme,pin_hash,pin_salt,
  argon2_memory_kib,argon2_iterations,argon2_parallelism,enabled
) VALUES (
  '10000000-0000-4000-8000-000000000001',1,'argon2id-v1',
  decode(repeat('11',32),'hex'),decode(repeat('22',16),'hex'),19456,2,1,true
);

DO $$
DECLARE
  v_outcome jsonb;
  v_replay jsonb;
  v_created timestamptz;
  v_expires timestamptz;
  v_count bigint;
BEGIN
  v_outcome := public.hbd_enter_protected_experience(
    '20000000-0000-4000-8000-000000000001',decode(repeat('31',32),'hex'),1,
    'entry-command-1',decode(repeat('41',32),'hex'),'dev_protected_entry_v1','/world/before-we-grew-up'
  );

  IF (SELECT count(*) FROM jsonb_object_keys(v_outcome)) <> 5
     OR NOT (v_outcome ?& ARRAY['pre_resolution_access_grant_id','entry_context_id','destination','created_at','expires_at']) THEN
    RAISE EXCEPTION 'protected entry outcome shape invalid: %', v_outcome;
  END IF;
  IF v_outcome ? 'credential_hash' OR v_outcome ? 'pin_hash' OR v_outcome ? 'pin_salt' THEN
    RAISE EXCEPTION 'protected entry outcome leaked verifier material';
  END IF;
  IF v_outcome->>'pre_resolution_access_grant_id' <> '20000000-0000-4000-8000-000000000001'
     OR v_outcome->>'entry_context_id' <> 'dev_protected_entry_v1'
     OR v_outcome->>'destination' <> '/world/before-we-grew-up' THEN
    RAISE EXCEPTION 'protected entry outcome values invalid: %', v_outcome;
  END IF;

  SELECT created_at,expires_at INTO v_created,v_expires
  FROM public.pre_resolution_access_grant
  WHERE pre_resolution_access_grant_id='20000000-0000-4000-8000-000000000001';
  IF NOT FOUND THEN RAISE EXCEPTION 'protected entry grant missing'; END IF;
  IF octet_length((SELECT credential_hash FROM public.pre_resolution_access_grant WHERE pre_resolution_access_grant_id='20000000-0000-4000-8000-000000000001')) <> 32 THEN
    RAISE EXCEPTION 'grant credential hash must be exactly 32 bytes';
  END IF;
  IF v_created <> transaction_timestamp() THEN RAISE EXCEPTION 'grant created_at must use canonical transaction time'; END IF;
  IF v_expires - v_created <> interval '15 minutes' THEN RAISE EXCEPTION 'grant expiry must be exactly 15 minutes'; END IF;

  v_replay := public.hbd_enter_protected_experience(
    '20000000-0000-4000-8000-000000000002',decode(repeat('32',32),'hex'),1,
    'entry-command-1',decode(repeat('41',32),'hex'),'dev_protected_entry_v1','/world/before-we-grew-up'
  );
  IF v_replay IS DISTINCT FROM v_outcome THEN RAISE EXCEPTION 'exact replay must return canonical original outcome'; END IF;
  SELECT count(*) INTO v_count FROM public.pre_resolution_access_grant;
  IF v_count <> 1 THEN RAISE EXCEPTION 'exact replay must leave exactly one grant'; END IF;
  SELECT count(*) INTO v_count FROM public.idempotency_record WHERE command_scope='PROTECTED_ENTER' AND idempotency_key='entry-command-1';
  IF v_count <> 1 THEN RAISE EXCEPTION 'exact replay must leave one idempotency record'; END IF;

  BEGIN
    PERFORM public.hbd_enter_protected_experience(
      '20000000-0000-4000-8000-000000000003',decode(repeat('33',32),'hex'),1,
      'entry-command-1',decode(repeat('42',32),'hex'),'dev_protected_entry_v1','/world/before-we-grew-up'
    );
    RAISE EXCEPTION 'idempotency hash mismatch unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='idempotency hash mismatch unexpectedly accepted' THEN RAISE; END IF;
    IF position('idempotency request hash mismatch' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected idempotency mismatch error: %', SQLERRM; END IF;
  END;
  SELECT count(*) INTO v_count FROM public.pre_resolution_access_grant;
  IF v_count <> 1 THEN RAISE EXCEPTION 'mismatch must not create second grant'; END IF;

  BEGIN
    PERFORM public.hbd_enter_protected_experience(
      '20000000-0000-4000-8000-000000000004',decode(repeat('34',32),'hex'),2,
      'entry-command-generation',decode(repeat('43',32),'hex'),'dev_protected_entry_v1','/world/before-we-grew-up'
    );
    RAISE EXCEPTION 'stale policy generation unexpectedly accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='stale policy generation unexpectedly accepted' THEN RAISE; END IF;
    IF position('protected entry policy generation changed' in SQLERRM)=0 THEN RAISE EXCEPTION 'unexpected policy-generation error: %', SQLERRM; END IF;
  END;
  SELECT count(*) INTO v_count FROM public.pre_resolution_access_grant;
  IF v_count <> 1 THEN RAISE EXCEPTION 'policy-generation conflict must not create grant'; END IF;
  SELECT count(*) INTO v_count FROM public.idempotency_record WHERE command_scope='PROTECTED_ENTER' AND idempotency_key='entry-command-generation';
  IF v_count <> 0 THEN RAISE EXCEPTION 'policy-generation conflict must not create idempotency record'; END IF;
END $$;

ROLLBACK;
SELECT 'enter_protected_experience_command_test PASS' AS result;
