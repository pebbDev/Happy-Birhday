# Tencent / Supabase CD — activation and safety

Status: **Local CD scaffold + read-only provider inspection. No hosted migrations or backend deployment have been executed.**

## Accepted boundaries
- Tencent Fastify runtime remains **UNDECIDED** in Notion Infrastructure 04.7 and IaC & Deployment Authority 18.3: SCF vs CVM/container, region, ingress, health/rollback and deployment credential authority are not yet specified. Do not fabricate an SCF or SSH deployment command.
- Supabase PostgreSQL canonical schema authority is **supabase/migrations/**. Never apply Prisma Migrate or Prisma db push to this database. Hosted DEV is not Production, and remote SQL migration history must be reconciled before writes.
- Trusted GitHub Actions remains the single cross-provider release orchestrator: protected release tag → Supabase compatibility/migrations → Tencent API deploy/health → Vercel production promotion. Deployment across clouds is **not atomic**.

## DEV DB pipeline (.github/workflows/supabase-dev-migrations.yml)
Manual **workflow_dispatch** from the reviewed **main** branch only: choose plan (default, read-only) or apply (requires repository/environment opt-in AND the explicit `APPLY-DEV` confirmation input). The workflow verifies the chosen project is exactly the previously inspected Happy Birthday Diana DEV reference `daelpglayqvibpsbklwe`, before linking. Never re-point this DEV workflow at Production.
GitHub Environment **supabase-dev** must be configured with:
- secrets SUPABASE_ACCESS_TOKEN and SUPABASE_DB_PASSWORD, for **DEV only**;
- variable SUPABASE_PROJECT_REF = `daelpglayqvibpsbklwe`, verified hosted **Happy Birthday Diana DEV** project ref (not the local config.toml project_id);
- variable ENABLE_SUPABASE_DEV_APPLY = false/unset initially.

Workflow uses pinned Supabase CLI via setup-cli action. Always compares remote ledger and runs db push --dry-run before applying. Apply requires ENABLE_SUPABASE_DEV_APPLY=true; configure required reviewers before enabling. **Stop on ledger drift**; do not run migration repair or linked reset automatically.

## PRODUCTION pipeline (.github/workflows/cd.yml)
Current workflow can only inspect Supabase Production migration ledger and run a **read-only dry-run**. It is guarded by all of:
- trusted successful Create Release workflow_run from main;
- ENABLE_PRODUCTION_CD=true and ENABLE_SUPABASE_PROD_PLAN=true;
- GitHub Environment **production**, with required reviewers and restricted deployment branches;
- secrets SUPABASE_ACCESS_TOKEN + SUPABASE_DB_PASSWORD for separate Production project;
- variable SUPABASE_PROJECT_REF for a separately identified, verified Production project. The workflow explicitly rejects the DEV ref `daelpglayqvibpsbklwe`.

**Production db push/apply deliberately NOT IMPLEMENTED** until Tencent backend adapter and database compatibility/recovery plan are accepted. A Tencent backend job is hard-blocked and exits with a clear error if ENABLE_TENCENT_CD=true; it does not deploy. Existing Vercel Production job needs both Supabase and Tencent gates, so it cannot promote early.

Production activation checklist: select Tencent runtime, region, HTTPS ingress, Prisma DB pooling/TLS, COS secret identity, immutable build packaging, health verification, cutover/rollback; validate Supabase migration history in an isolated environment; test forward/rollback compatibility; provision GitHub environments and least privilege tokens; test non-prod pipeline; only then implement the Tencent deployment adapter and DB apply stage.

## Supabase read-only inspection, 2026-10-25

- Project: `Happy Birthday Diana`, `daelpglayqvibpsbklwe`, Singapore, PostgreSQL 17.11, `ACTIVE_HEALTHY`. This is the previously documented hosted DEV project, not a declared Production database.
- Exactly **13 remote migration versions and names** match the 13 tracked SQL migration filenames under `supabase/migrations/` at the inspected GitHub `main`. This validates the *migration ledger only*: it is not a byte-level schema-drift proof.
- 16 application tables in `public`, all with RLS enabled. Existing deny-direct-client policies cover 14 tables. Two new access tables have RLS on without policies (default deny), and the Supabase security advisor reports them as two informational findings, not confirmed exposure.
- Four previously deployed Supabase Edge Functions remain **ACTIVE**, all currently reported `verify_jwt=false`. This setting alone is not sufficient evidence of an exploit; review each function's internal authentication and upstream dependencies before disabling/removing anything.
- Project contains records. Do not `db reset --linked`, run an unreviewed `db push`, repair the remote migration ledger, or assume the database is disposable.
- No Supabase GitHub Branching environments currently exist. Do not create paid preview branches without separately evaluating costs and authorization.


## Tencent Cloud inspection and safe DEV rollout preparation (2026-10-25)

- Read-only `tccli sts GetCallerIdentity` succeeded, but the configured **local CLI principal is Tencent root**. **Never put this root credential or configuration file into GitHub Actions**. Root remains local inspection-only; rotate if exposure is suspected.
- Read-only inventory returned **zero SCF functions, zero CVM instances and zero Lighthouse instances in both `ap-singapore` and `ap-jakarta`**. This does not prove absence in every Tencent region. No server to receive a backend deploy has been identified, and no Tencent infrastructure was created.
- An existing `tccli-cvm-operator` CAM sub-user exists but its broad managed `*FullAccess` policies are **not approved for CI deployment**. Provision/authorize a dedicated scoped CI/CD identity only after the deployment target/region/resources are determined.
- The checked-in Fastify API requires Node >=22.12.0. Current Tencent SCF **managed** Node runtimes documented up through Node.js 20.19; using SCF requires a separately designed image/custom runtime, not simply setting Node 24. A Node 24 compatible persistent CVM/Lighthouse (or container) is a **candidate**, not yet accepted.
- Singapore (`ap-singapore`) is a sensible DEV *candidate* alongside Supabase Singapore, but requires explicit instance selection and network/cost review. Never assume SCF or SSH ingress exists.
- GitHub Environment `tencent-dev` was provisioned with main-only deployment branch, required reviewers `pebbDev` and `febriyadi`, no self review and no admin bypass; variables `TENCENT_REGION=ap-singapore`, `TENCENT_RUNTIME=UNSELECTED`, `ENABLE_TENCENT_DEV_DEPLOY=false`. **No Tencent credentials have been added to GitHub.**
- `.github/workflows/tencent-dev-preflight.yml` provides **no-cloud-write** manual Node 24 production artifact build/smoke, SHA-256 digest, and short-lived archived artifact; `ci.yml` additionally compiles and smokes the API on PRs. This is preflight, **not CD deployment**, and requires merging into `main` for manual dispatch.
- Fastify currently only exposes health endpoints and not the protected business API. Do not expose it through a publicly reachable host as a production backend before required auth, networking, TLS, and runtime configuration are implemented.
- Keep `ENABLE_TENCENT_DEV_DEPLOY=false`, `ENABLE_TENCENT_CD=false`, and `ENABLE_PRODUCTION_CD=false` until a scoped CAM identity, confirmed host/region, immutable deployment artifact, external HTTPS ingress, `/health/ready` against scoped Supabase DEV connection, rollback and version compatibility checks have all been approved and tested.
- Next implementation milestone after host provisioning: establish host OS/Node 24/port/service manager, network/egress and TLS, secure runtime `DATABASE_URL` (not in GitHub artifacts), deploy to nonproduction staging with immutable release path and atomic service cutover, verify /health endpoints, and validate rollback without database schema rollback.

Tencent refs:
- https://intl.cloud.tencent.com/ind/document/product/583/11060 (SCF Node runtimes)
- https://intl.cloud.tencent.com/ind/document/product/583/40678 (SCF Web Function bootstrap)
- https://indonesia.tencentcloud.com/document/product/213/10315 (CAM principle of least privilege)

## References
Notion 04.7 Infrastructure & Platform: https://app.notion.com/p/3f60c425903481abaac9e486130a5765
Notion 18.3 IaC & Deployment Authority: https://app.notion.com/p/4000c42590348157acbeff6a1a317cc5
Supabase Migrations: https://supabase.com/docs/guides/deployment/database-migrations
Supabase CI/CD environments: https://supabase.com/docs/guides/deployment/managing-environments
CLI command reference: https://supabase.com/docs/reference/cli/global-flags
