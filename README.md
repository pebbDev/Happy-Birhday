# Happy Birthday Platform

**pnpm Workspaces monorepo** for Happy Birthday Diana. Feature-first Fastify/TypeScript backend with Prisma; Vue/Vite frontend is planned but not yet implemented.

## Repository layout

```text
Happy-Birthday-Platform/
├── apps/
│   ├── api/                 # Fastify / Clean Architecture / Prisma
│   └── web/                 # Vue/Vite reserved workspace
├── packages/
│   └── contracts/           # Active OpenAPI contract
│       └── openapi/openapi.yaml
├── supabase/
│   ├── migrations/          # Exclusive canonical PostgreSQL SQL migration authority
│   ├── tests/database/      # Database invariants
│   └── config.toml
├── scripts/                 # Verification
├── docs/                    # Design documents and historical notes
├── package.json
├── pnpm-workspace.yaml
└── pnpm-lock.yaml
```

### Package ownership

- `@happy-birthday/api`: Fastify Node.js runtime, class-based application services, domain, Prisma infrastructure.
- `@happy-birthday/web`: reserved Vue frontend package, **no client implementation yet**.
- `@happy-birthday/contracts`: OpenAPI assets; shared TypeScript DTO generation is future work. No direct sharing of Prisma, secrets or domain entities.
- `supabase/`: managed PostgreSQL schema, SQL functions and database invariants. **Not** the application runtime.

## Infrastructure decision (October 2026)

- **Cloudflare DNS, proxy, WAF and Workers: deferred.** There is no active Cloudflare zone, Wrangler configuration, Worker runtime, DNS or WAF configuration in this repository. Do not treat historical Cloudflare specifications as live instructions.
- **Frontend:** Vercel is the planned hosting provider for `apps/web`; the Vue frontend is not implemented yet.
- **Backend DEV (verified 2026-10-26):** Tencent SCF `hbd-api-dev` is deployed in `ap-singapore`, with CAM-signed operator HTTPS and Supabase DEV readiness passing. This is **not** the public product ingress; automated Tencent DEV CD and all Production CD are still disabled. See [`infra/tencent/DEV-RUNBOOK.md`](infra/tencent/DEV-RUNBOOK.md).
- **Database:** Supabase provides PostgreSQL; SQL migrations under `supabase/migrations/` remain authoritative.
- The superseded Cloudflare DEV Worker ingress plan is preserved for historical reference only under `docs/archive/cloudflare-deferred/`. No Cloudflare setup is required for local development or CI.

## Docker Option B — isolated local PostgreSQL testing

Docker runs **only** an isolated PostgreSQL 17 test database (not Fastify or the future Vue frontend). The Windows helper uses a separate Docker Compose project `hbd-pg-test`, loopback-only `127.0.0.1:55432`, random gitignored local password, and a retained test-only volume. The existing Supabase local DB and hosted DEV/PROD environments are untouched.

```powershell
pnpm run db:test:up       # start database
pnpm run db:test:migrate  # apply canonical Supabase SQL migration files only to test DB
pnpm run db:test:sql      # run SQL regression files
pnpm run db:test:integration # Fastify + Prisma test against local Docker PostgreSQL
pnpm run db:test:dev-api  # run Fastify natively with Docker test DB
pnpm run db:test:down     # stop; retains test volume
# Or: pnpm run db:test:all (migrations + SQL + Fastify/Prisma integration)
```

Full instructions and limitations: `infra/docker/README.md`. Database-only PostgreSQL is not a complete local Supabase platform. **Do not** run `prisma db push` or `prisma migrate` for the canonical schema.

## Development

Use **Node.js >=22.12** and **pnpm 12.15.0**.

```powershell
pnpm install --frozen-lockfile
pnpm run prisma:generate
pnpm run prisma:validate
pnpm run check
pnpm run dev:api
```

`pnpm run dev:api` starts the only implemented runtime. There is no `dev:web` script because Vue has not been created. All package dependencies are locked in one root `pnpm-lock.yaml`; do not reintroduce `package-lock.json` under workspace packages.

## Actual implementation status

This is a structural and dependency-management migration, **not a full business feature migration**. Fastify currently implements only `GET /health/live` and `GET /health/ready`; protected operations remain unavailable. The old Deno/Cloudflare/Edge source was archived outside the Git checkout in the earlier restructuring; subsequent Tencent SCF DEV deployment is documented separately.

`supabase/migrations/` remains the single database-schema migration authority. Prisma is only an ORM mapping. The earlier repository restructuring did not itself execute migrations or deploy cloud services; Tencent SCF DEV was subsequently deployed and independently health-checked. No hosted migrations or Git remote changes were made by this cleanup.

## Windows local alias

`D:\Happy-Birthday-Platform` is presently a junction to the same Git worktree at physical path `D:\Happy Birhday`, due to an unrelated folder lock during the earlier enterprise rename. The GitHub remote is unchanged.
