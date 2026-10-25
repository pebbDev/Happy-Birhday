# Release automation — Happy Birthday Platform

Status: **Configured on a feature branch only. Production activation is intentionally pending.**

## Source of the workflow

Adapted from `hammercode-dev/dashboard-yayasan-peduli-ilmu/.github/workflows` while keeping this repository's API, PostgreSQL and Vue/Vercel validations in a single CI workflow.

| Workflow | Trigger | Responsibility |
| --- | --- | --- |
| `ci.yml` | PR/push `main`; manual dispatch | API/Prisma, PostgreSQL migrations and SQL regression, Vue typecheck/lint/tests/SSG+CSR build, GitHub Actions YAML lint |
| `prepare-release.yml` | Push to `main`, except release merges | Compute SemVer from Conventional Commits; open `release/vX.Y.Z` PR; explicitly dispatch CI checks |
| `create-release.yml` | Push to `main` after version change | Validate changed root version, annotate tag `vX.Y.Z`, publish GitHub Release |
| `cd.yml` | Successful **Create Release** workflow_run | Opt-in trusted cross-provider CD: Supabase PROD dry-run → Tencent hard gate → Vercel Production promotion (currently blocked) |
| `supabase-dev-migrations.yml` | Manual `workflow_dispatch` | Supabase DEV ledger/dry-run; optional approved DEV apply |

The monorepo version is the root `package.json#version` (starting at `0.1.0`). Individual workspace package versions are **not** published or bumped in this workflow. Conventional Commits are evaluated since the last `v*` tag: `BREAKING CHANGE` / `feat!:` → major, `feat:` → minor, otherwise patch. With no existing tag, the initial calculation considers the repository history.

## Before enabling Production

1. In **Vercel**, verify `happy-birthday-web` → Settings → Environments → Production → Branch Tracking = `main`. This project previously treated a feature branch push as production; verify before further Git pushes.
2. Configure `apps/web/vercel.json` as checked in: Git auto-deploy of **main** is disabled, while other branches retain Preview. This avoids a second Production deploy that would bypass GitHub approval. Explicit Vercel CLI CD is unaffected.
3. In **GitHub**, create Environment `production` with **required reviewers** and deployment branches limited to **main**. Do this **before** enabling the flag; a named environment without protection does not itself require review.
4. Set GitHub repository **variables** (non-secret): `VERCEL_ORG_ID=team_tUI2OLsX7oc0ppLmXJUz4M0p` and `VERCEL_PROJECT_ID=prj_pKN4O9pgMbsLHdTcLdzVXDX1Zmla`.
5. Set GitHub Environment `production` **secret**: `VERCEL_TOKEN`, issued with minimal access to this Vercel project. Never send tokens to chat, put them in browser build variables, or commit `.vercel/` environment files.
6. `ENABLE_PRODUCTION_CD` remains unset/false. Before any activation, separately validate production Supabase project reference/secrets and `ENABLE_SUPABASE_PROD_PLAN`; Tencent hosting adapter and `ENABLE_TENCENT_CD` remain blocked. The frontend deployment job cannot run before both database and Tencent jobs succeed.
7. Enable **Allow GitHub Actions to create and approve pull requests** in GitHub Actions repository settings for the Prepare Release bot, subject to your repository permissions. This does not authorize auto-merging.
8. Set GitHub branch protection / ruleset for `main` after CI job names have been verified: require API, database, Vue frontend, and workflow-lint checks, review before merge, and no unauthorized direct pushes.

## Release lifecycle

1. Reviewed feature PR merges to `main` → existing validation jobs plus Prepare Release.
2. Prepare Release produces a `release/vX.Y.Z` version-only PR. Because it uses `GITHUB_TOKEN`, it explicitly sends `workflow_dispatch` for unified CI to get CI results. The PR still requires human review.
3. Release PR merges → Create Release checks that `package.json` changed and creates an immutable-intent annotated tag plus GitHub Release.
4. CD follows successful Create Release via `workflow_run`, but all provider jobs are disabled by default. An authorized Production plan only checks the Supabase migration ledger and dry-runs SQL. Tencent deployment is not selected/implemented and deliberately fails closed if activated. Vercel promotion depends on successful database and Tencent gates and therefore cannot run yet.
5. Before future Production mutation, choose the Tencent hosting/runtime adapter, separately authorize compatible SQL migration/apply and recovery, and confirm an actual full release smoke/rollback path. A code rollback does not roll back database schema. See `.github/TENCENT-SUPABASE-CD.md`.

## Known limitations and safeguards

- This is **not** an end-to-end verified automated release: no release PR, tag, GitHub Release or Production deployment has been created.
- GitHub Actions PRs created by `GITHUB_TOKEN` can enter an approval-required CI state; explicit `workflow_dispatch` requests are included for the release branch. Confirm required checks attach to the release PR and approve workflows when prompted before enabling auto-CD.
- `workflow_run` is privileged: CD checks out only the exact SHA on trusted `main`; never ingest untrusted artifacts or fork checkout into the production job.
- Vercel Preview remains separate from GitHub CD. Git auto-deploy production is disabled by the repo configuration for `main`.
- No extra long-lived dependency bot, global npm versioning automation, or automatic Production release is enabled.
- Review action versions periodically; CD uses Vercel CLI `65.1.0` pinned to the verified CLI used on Vercel Preview. GitHub Actions hosted runner, access policies, Vercel quota and third-party action versions should be revalidated before enabling.
