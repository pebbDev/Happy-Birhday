CREATE TABLE public.protected_entry_policy (
  protected_entry_policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  generation bigint NOT NULL,
  verifier_scheme text NOT NULL,
  pin_hash bytea NOT NULL,
  pin_salt bytea NOT NULL,
  argon2_memory_kib integer NOT NULL,
  argon2_iterations integer NOT NULL,
  argon2_parallelism integer NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  rotated_at timestamptz,
  CONSTRAINT chk_protected_entry_policy_generation CHECK (generation >= 1),
  CONSTRAINT uq_protected_entry_policy_generation UNIQUE (generation),
  CONSTRAINT chk_protected_entry_policy_verifier_scheme CHECK (verifier_scheme = 'argon2id-v1'),
  CONSTRAINT chk_protected_entry_policy_pin_hash CHECK (octet_length(pin_hash) = 32),
  CONSTRAINT chk_protected_entry_policy_pin_salt CHECK (octet_length(pin_salt) = 16),
  CONSTRAINT chk_protected_entry_policy_argon2_memory CHECK (argon2_memory_kib >= 19456),
  CONSTRAINT chk_protected_entry_policy_argon2_iterations CHECK (argon2_iterations >= 2),
  CONSTRAINT chk_protected_entry_policy_argon2_parallelism CHECK (argon2_parallelism >= 1),
  CONSTRAINT chk_protected_entry_policy_rotated_at CHECK (rotated_at IS NULL OR rotated_at >= created_at)
);

CREATE UNIQUE INDEX uq_protected_entry_policy_single_enabled
  ON public.protected_entry_policy ((enabled))
  WHERE (enabled = true);

ALTER TABLE public.protected_entry_policy ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE public.protected_entry_policy FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.protected_entry_policy TO postgres, service_role;

CREATE TABLE public.pre_resolution_access_grant (
  pre_resolution_access_grant_id uuid PRIMARY KEY,
  credential_hash bytea NOT NULL,
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  revoked_at timestamptz,
  CONSTRAINT uq_pre_resolution_access_grant_credential_hash UNIQUE (credential_hash),
  CONSTRAINT chk_pre_resolution_access_grant_credential_hash CHECK (octet_length(credential_hash) = 32),
  CONSTRAINT chk_pre_resolution_access_grant_expiry CHECK (expires_at > created_at),
  CONSTRAINT chk_pre_resolution_access_grant_consumed_at CHECK (consumed_at IS NULL OR consumed_at >= created_at),
  CONSTRAINT chk_pre_resolution_access_grant_revoked_at CHECK (revoked_at IS NULL OR revoked_at >= created_at)
);

ALTER TABLE public.pre_resolution_access_grant ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE public.pre_resolution_access_grant FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.pre_resolution_access_grant TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.hbd_enter_protected_experience(
  p_pre_resolution_access_grant_id uuid,
  p_credential_hash bytea,
  p_policy_generation bigint,
  p_idempotency_key text,
  p_request_hash bytea,
  p_entry_context_id text,
  p_destination text
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
  v_scope CONSTANT text := 'PROTECTED_ENTER';
  v_existing_hash bytea;
  v_existing_outcome jsonb;
  v_current_generation bigint;
  v_now timestamptz;
  v_expires_at timestamptz;
  v_outcome jsonb;
BEGIN
  IF p_pre_resolution_access_grant_id IS NULL THEN
    RAISE EXCEPTION 'pre-resolution access grant id must not be null';
  END IF;
  IF p_credential_hash IS NULL OR octet_length(p_credential_hash) <> 32 THEN
    RAISE EXCEPTION 'credential hash must be 32 bytes';
  END IF;
  IF p_request_hash IS NULL OR octet_length(p_request_hash) <> 32 THEN
    RAISE EXCEPTION 'request hash must be 32 bytes';
  END IF;
  IF p_idempotency_key IS NULL OR btrim(p_idempotency_key) = '' OR char_length(p_idempotency_key) > 128 THEN
    RAISE EXCEPTION 'idempotency key must be 1-128 characters';
  END IF;
  IF p_entry_context_id IS NULL OR btrim(p_entry_context_id) = '' OR char_length(p_entry_context_id) > 128 THEN
    RAISE EXCEPTION 'entry context id must be 1-128 characters';
  END IF;
  IF p_destination IS NULL OR btrim(p_destination) = '' OR char_length(p_destination) > 512 THEN
    RAISE EXCEPTION 'destination must be 1-512 characters';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(v_scope || ':' || p_idempotency_key, 0));

  SELECT request_hash, outcome_jsonb
    INTO v_existing_hash, v_existing_outcome
  FROM public.idempotency_record
  WHERE command_scope = v_scope
    AND idempotency_key = p_idempotency_key;

  IF FOUND THEN
    IF v_existing_hash <> p_request_hash THEN
      RAISE EXCEPTION 'idempotency request hash mismatch';
    END IF;
    RETURN v_existing_outcome;
  END IF;

  SELECT generation
    INTO v_current_generation
  FROM public.protected_entry_policy
  WHERE enabled = true
  FOR UPDATE;

  IF NOT FOUND OR v_current_generation <> p_policy_generation THEN
    RAISE EXCEPTION 'protected entry policy generation changed';
  END IF;

  v_now := transaction_timestamp();
  v_expires_at := v_now + interval '15 minutes';

  INSERT INTO public.pre_resolution_access_grant(
    pre_resolution_access_grant_id,
    credential_hash,
    created_at,
    expires_at
  ) VALUES (
    p_pre_resolution_access_grant_id,
    p_credential_hash,
    v_now,
    v_expires_at
  );

  v_outcome := jsonb_build_object(
    'pre_resolution_access_grant_id', p_pre_resolution_access_grant_id,
    'entry_context_id', p_entry_context_id,
    'destination', p_destination,
    'created_at', v_now,
    'expires_at', v_expires_at
  );

  INSERT INTO public.idempotency_record(
    command_scope,
    idempotency_key,
    request_hash,
    outcome_jsonb
  ) VALUES (
    v_scope,
    p_idempotency_key,
    p_request_hash,
    v_outcome
  );

  RETURN v_outcome;
END;
$function$;

ALTER FUNCTION public.hbd_enter_protected_experience(uuid, bytea, bigint, text, bytea, text, text)
  SET search_path = '';

REVOKE ALL ON FUNCTION public.hbd_enter_protected_experience(uuid, bytea, bigint, text, bytea, text, text)
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.hbd_enter_protected_experience(uuid, bytea, bigint, text, bytea, text, text)
  TO postgres, service_role;
