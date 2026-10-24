BEGIN;
DO $$ BEGIN
  BEGIN INSERT INTO public.async_session(state,resource_version) VALUES ('WAITING',-1); RAISE EXCEPTION 'negative version accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN INSERT INTO public.async_session(state,invite_ready_at,response_start_deadline_at) VALUES ('WAITING',now(),now()-interval '1 second'); RAISE EXCEPTION 'invalid start deadline accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN INSERT INTO public.async_session(state,responding_deadline_at) VALUES ('RESPONDING',now()+interval '1 hour'); RAISE EXCEPTION 'deadline without start accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN INSERT INTO public.async_session(state,completed_at,expired_at) VALUES ('COMPLETED',now(),now()); RAISE EXCEPTION 'dual terminal timestamps accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
END $$;
ROLLBACK;
SELECT 'async_state_constraints_test PASS' AS result;
