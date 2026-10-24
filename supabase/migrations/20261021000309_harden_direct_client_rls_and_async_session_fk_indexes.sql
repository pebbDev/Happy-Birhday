-- Keep the public schema fail-closed for browser/client roles until direct Data API access
-- is intentionally designed. Restrictive policies remain deny-by-default even if a
-- permissive policy is added later without removing this guard.

DROP POLICY IF EXISTS deny_direct_client_access ON public.participant_access_capability;
CREATE POLICY deny_direct_client_access ON public.participant_access_capability
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.participant;
CREATE POLICY deny_direct_client_access ON public.participant
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.protected_access_session;
CREATE POLICY deny_direct_client_access ON public.protected_access_session
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.media_asset;
CREATE POLICY deny_direct_client_access ON public.media_asset
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.personal_memory_media;
CREATE POLICY deny_direct_client_access ON public.personal_memory_media
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.personal_memory;
CREATE POLICY deny_direct_client_access ON public.personal_memory
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.async_response_media;
CREATE POLICY deny_direct_client_access ON public.async_response_media
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.async_response;
CREATE POLICY deny_direct_client_access ON public.async_response
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.async_session;
CREATE POLICY deny_direct_client_access ON public.async_session
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.canonical_memory_media;
CREATE POLICY deny_direct_client_access ON public.canonical_memory_media
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.canonical_memory;
CREATE POLICY deny_direct_client_access ON public.canonical_memory
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.responder_continuation_authority;
CREATE POLICY deny_direct_client_access ON public.responder_continuation_authority
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.session_participation;
CREATE POLICY deny_direct_client_access ON public.session_participation
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_direct_client_access ON public.idempotency_record;
CREATE POLICY deny_direct_client_access ON public.idempotency_record
  AS RESTRICTIVE FOR ALL TO anon, authenticated
  USING (false) WITH CHECK (false);

-- Cover the two async_session foreign keys reported by the Supabase performance advisor.
CREATE INDEX IF NOT EXISTS idx_async_session_active_editing_access_session_id
  ON public.async_session (active_editing_access_session_id);

CREATE INDEX IF NOT EXISTS idx_async_session_current_editor_session
  ON public.async_session (current_editor_session_participation_id, async_session_id);