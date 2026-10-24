-- Local test-only Supabase-compatible role names needed by canonical migrations.
-- No LOGIN grants: these are placeholders for grants/RLS tests, not JWT/API auth.
-- Never run this file on hosted Supabase.
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN BYPASSRLS;
