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

## References
Notion 04.7 Infrastructure & Platform: https://app.notion.com/p/3f60c425903481abaac9e486130a5765
Notion 18.3 IaC & Deployment Authority: https://app.notion.com/p/4000c42590348157acbeff6a1a317cc5
Supabase Migrations: https://supabase.com/docs/guides/deployment/database-migrations
Supabase CI/CD environments: https://supabase.com/docs/guides/deployment/managing-environments
CLI command reference: https://supabase.com/docs/reference/cli/global-flags
