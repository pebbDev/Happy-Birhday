\set ON_ERROR_STOP on

BEGIN;

INSERT INTO public.participant(participant_id, display_name)
VALUES ('00000000-0000-0000-0000-000000000001'::uuid, 'Diana Test');

DO $$
BEGIN
  BEGIN
    INSERT INTO public.participant(display_name) VALUES ('   ');
    RAISE EXCEPTION 'blank participant display_name unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

DO $$
BEGIN
  BEGIN
    INSERT INTO public.participant_access_capability(participant_id, capability_type, token_hash, expires_at)
    VALUES ('00000000-0000-0000-0000-000000000001'::uuid, 'OTHER', decode(repeat('aa', 32), 'hex'), transaction_timestamp() + interval '1 hour');
    RAISE EXCEPTION 'invalid capability_type unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

DO $$
BEGIN
  BEGIN
    INSERT INTO public.participant_access_capability(participant_id, capability_type, token_hash, expires_at)
    VALUES ('00000000-0000-0000-0000-000000000001'::uuid, 'INVITE', decode('aa', 'hex'), transaction_timestamp() + interval '1 hour');
    RAISE EXCEPTION 'short capability token hash unexpectedly accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

INSERT INTO public.participant_access_capability(participant_id, capability_type, token_hash, expires_at)
VALUES ('00000000-0000-0000-0000-000000000001'::uuid, 'INVITE', decode(repeat('01', 32), 'hex'), transaction_timestamp() + interval '1 hour');

DO $$
BEGIN
  BEGIN
    INSERT INTO public.participant_access_capability(participant_id, capability_type, token_hash, expires_at)
    VALUES ('00000000-0000-0000-0000-000000000001'::uuid, 'RECOVERY', decode(repeat('01', 32), 'hex'), transaction_timestamp() + interval '2 hours');
    RAISE EXCEPTION 'duplicate capability token hash unexpectedly accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
END $$;

ROLLBACK;
SELECT 'identity_constraints_test PASS' AS result;
