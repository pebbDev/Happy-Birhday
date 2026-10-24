# @happy-birthday/api

Fastify 5 + TypeScript + Prisma 7 API, running inside the Happy Birthday Platform **pnpm workspace**.

## Structure

```text
apps/api/
  src/
    bootstrap/        # container and Fastify composition
    modules/
      health/         # live + readiness health operations
      async-together/ # internal read-side domain/application foundation
    platform/         # config and Prisma adapters
    tests/
  prisma/schema.prisma
  prisma.config.ts
  package.json
  tsconfig.json
```

Business modules implement Clean Architecture with domain + application + adapters; controllers/services/repositories are classes where appropriate. Health does not require fictitious domain entities.

## Commands (from repository root)

```powershell
pnpm install
pnpm run prisma:generate
pnpm run prisma:validate
pnpm run typecheck
pnpm run test
pnpm run dev:api
```

Or from `apps/api/`: `pnpm dev`, `pnpm typecheck`, `pnpm test`.

## Current functionality

- `GET /health/live`: process health; no database needed.
- `GET /health/ready`: generic 200/503 depending on PostgreSQL connectivity through Prisma.
- Private/session operations: **NOT exposed**. The previous Deno implementation and nine Edge Functions were archived during the cleanup, not ported.

Prisma maps canonical tables but does NOT own migrations. The only database migration history is in `../../supabase/migrations/`. Do not run competing `prisma db push` or `prisma migrate dev` against the canonical database. Reimplement trusted participant authorization, replay protection, idempotency, deadlines and atomic mutation semantics before opening protected endpoints.

Cloud deployments have not been changed by source restructuring.
