# Tencent / Supabase CD — activation and safety

Status: **Scaffold configured on a new feature branch; no hosted migrations or backend deployment have been executed.**

## Accepted boundaries
- Tencent Fastify runtime remains **UNDECIDED** in Notion Infrastructure 04.7 and IaC & Deployment Authority 18.3: SCF vs CVM/container, region, ingress, health/rollback and deployment credential authority are not yet specified. Do not fabricate an SCF or SSH deployment command.
- Supabase PostgreSQL canonical schema authority is **supabase/migrations/**. Never apply Prisma Migrate or Prisma db push to this database. Hosted DEV is not Production, and remote SQL migration history must be reconciled before writes.
- Trusted GitHub Actions remains the single cross-provider release orchestrator: protected release tag → Supabase compatibility/migrations → Tencent API deploy/health → Vercel production promotion. Deployment across clouds is **not atomic**.

## DEV DB pipeline (.github/workflows/supabase-dev-migrations.yml)
Manual **workflow_dispatch** from the reviewed **main** branch only: choose plan (default, read-only) or apply (requires explicit opt-in).
GitHub Environment **supabase-dev** must be configured with:
- secrets SUPABASE_ACCESS_TOKEN and SUPABASE_DB_PASSWORD, for **DEV only**;
- variable SUPABASE_PROJECT_REF, hosted 20-character project reference (not local config.toml project_id);
- variable ENABLE_SUPABASE_DEV_APPLY = false/unset initially.

Workflow uses pinned Supabase CLI via setup-cli action. Always compares remote ledger and runs db push --dry-run before applying. Apply requires ENABLE_SUPABASE_DEV_APPLY=true; configure required reviewers before enabling. **Stop on ledger drift**; do not run migration repair or linked reset automatically.

## PRODUCTION pipeline (.github/workflows/cd.yml)
Current workflow can only inspect Supabase Production migration ledger and run a **read-only dry-run**. It is guarded by all of:
- trusted successful Create Release workflow_run from main;
- ENABLE_PRODUCTION_CD=true and ENABLE_SUPABASE_PROD_PLAN=true;
- GitHub Environment **production**, with required reviewers and restricted deployment branches;
- secrets SUPABASE_ACCESS_TOKEN + SUPABASE_DB_PASSWORD for separate Production project;
- variable SUPABASE_PROJECT_REF for separate Production project.

**Production db push/apply deliberately NOT IMPLEMENTED** until Tencent backend adapter and database compatibility/recovery plan are accepted. A Tencent backend job is hard-blocked and exits with a clear error if ENABLE_TENCENT_CD=true; it does not deploy. Existing Vercel Production job needs both Supabase and Tencent gates, so it cannot promote early.

Production activation checklist: select Tencent runtime, region, HTTPS ingress, Prisma DB pooling/TLS, COS secret identity, immutable build packaging, health verification, cutover/rollback; validate Supabase migration history in an isolated environment; test forward/rollback compatibility; provision GitHub environments and least privilege tokens; test non-prod pipeline; only then implement the Tencent deployment adapter and DB apply stage.

## References
Notion 04.7 Infrastructure & Platform: https://app.notion.com/p/3f60c425903481abaac9e486130a5765
Notion 18.3 IaC & Deployment Authority: https://app.notion.com/p/4000c42590348157acbeff6a1a317cc5
Supabase Migrations: https://supabase.com/docs/guides/deployment/database-migrations
Supabase CI/CD environments: https://supabase.com/docs/guides/deployment/managing-environments
CLI command reference: https://supabase.com/docs/reference/cli/global-flags
