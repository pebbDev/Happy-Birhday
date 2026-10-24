-- Pin trusted Async command functions to an empty search_path.
-- All application relation references in these functions are schema-qualified.

ALTER FUNCTION public.hbd_start_responding(uuid, uuid, uuid, bytea, bigint, text, bytea) SET search_path = '';
ALTER FUNCTION public.hbd_release_claim(uuid, uuid, uuid, bigint, text, bytea) SET search_path = '';
ALTER FUNCTION public.hbd_complete_async_session(uuid, uuid, uuid, bigint, text, bytea) SET search_path = '';
