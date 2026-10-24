# Isolated PostgreSQL for HBD development/integration tests (Docker Option B)

Fastify remains **native** (`pnpm dev:api`) and Vue remains separate. Docker runs only `postgres:17-alpine` for disposable, local development/tests. Hosted Supabase DEV/PROD, the pre-existing Supabase CLI local container on port 54322, and other Docker stacks must not be modified by these commands.

## Quick start (Windows PowerShell, from repository root)

```powershell
pnpm run db:test:up
pnpm run db:test:migrate
pnpm run db:test:sql
# or the combined command:
pnpm run db:test:all
pnpm run db:test:status
pnpm run db:test:dev-api # optional: native Fastify with local test DB URL supplied securely
pnpm run db:test:down
```

The helper creates `.env.docker.test` with a **random local-only password** if missing, and Docker Compose reads it via `--env-file`. The file is gitignored; only `.env.docker.test.example` is tracked.

- Compose project: `hbd-pg-test` (separate namespace from Supabase and other stacks)
- Database: `hbd_test`; user: `postgres`; PostgreSQL: **17** to match the root Supabase config's major version
- Host: `127.0.0.1:55432` (not public; override `HBD_PG_TEST_PORT` in the local env file)
- Data: Docker named volume `hbd-pg-test_hbd_pg_test_data`, retained on `down`
- Roles: minimal test-only `anon`, `authenticated`, `service_role` (not the complete Supabase platform)
- Migrations: canonical `supabase/migrations/*.sql`, mounted **read-only** and recorded in `hbd_test_meta.applied_migrations`; no `prisma migrate` or `db push`
- Tests: `supabase/tests/database/*.sql`, executed via `psql -v ON_ERROR_STOP=1`; application integration tests are a separate future step

**Important:** this is PostgreSQL compatibility testing, **not** full Supabase emulation. Authentication, PostgREST, Supavisor, cloud RLS, and platform-specific behavior still require a Supabase-compatible environment. PostgreSQL migrations may need platform-specific components; if a migration fails, the runner stops without attempting provider changes.

To connect Prisma locally for a bounded development session, set a temporary `DATABASE_URL` to `postgresql://postgres:<password-from-local-env>@127.0.0.1:55432/hbd_test?schema=public` in that session only. Never commit a connection string or silently overwrite a hosted database URL.

Do not run `docker compose down -v` unless you consciously intend to delete the **separate test volume**; this project's scripts never delete volumes. Do not use these fixtures as production database roles/secrets.
