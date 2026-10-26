# Tencent SCF + Supabase DEV — operational runbook

**State verified 2026-10-26.** This page supersedes the obsolete pre-provisioning proposal and sequential diagnostic notes. Scope is **DEV only**; production deployments and automated Tencent CD are disabled.

## Verified deployment

| Component | Verified status |
|---|---|
| Tencent region / namespace | `ap-singapore` / `hbd-dev` |
| SCF function / runtime | `hbd-api-dev` (`lam-4tgdr19q`), HTTP Web Function, Nodejs24.11, **Active** |
| DEV database | Supabase project `daelpglayqvibpsbklwe`; transaction pooler `:6543` |
| Transport | HTTPS Function URL, CAM signature required; anonymous probes rejected (HTTP `436`) |
| Liveness | Signed `GET /health/live`: **200**, `status=ok` |
| Readiness | Signed `GET /health/ready`: **200**, `status=ok` (Prisma `SELECT 1`) |
| Deployment artifact | Private COS `hbd-dev-private-media-1499705522` object `scf-artifacts/dev/hbd-api-dev-fastify-feba4e98bd166d1a.zip` |
| Logging | Tencent CLS SCF topic enabled, 7-day retention (may incur cost) |

The immutable artifact has SHA-256 prefix `feba4e98bd166d1a` and size `28,752,475` bytes; the Tencent update was acknowledged on 2026-10-26. A fresh signed smoke test returned **PASS** with SCF **Active**. These are health/readiness checks, **not** load, cost, frontend authorization, or full business-API acceptance tests.

## Security boundaries

- SCF has `DATABASE_URL` and `SUPABASE_DB_CA_CERT_BASE64` as runtime environment variables; they must never be printed, committed, sent in chat, or inserted into browser code. These DEV env vars are not a dedicated secrets-vault integration.
- `SUPABASE_DB_CA_CERT_BASE64` is the base64-encoded CA downloaded from the project's SSL configuration. Prisma's `pg` adapter requires TLS with explicit CA and `rejectUnauthorized: true`; never bypass certificate validation.
- The CAM-protected Function URL is intended for operator testing, **not directly for Vue clients**. Never embed CAM IAM keys in frontend assets. End-user ingress, authentication, HTTPS-only behavior, and bypass prevention remain to be designed.
- Local `cvm-operator` IAM has broad permissions and must **not** be used as GitHub Actions identity. Configure a least-privilege deploy principal before enabling automated CD.
- Keep Tencent DEV CD and all Production CD disabled until separately reviewed. The canonical database migration authority is `supabase/migrations/`; do not use Prisma Migrate or `db push` against hosted schema.
- If the DEV database password was previously shared, rotate it securely in Supabase, update SCF through the local hidden prompt, and verify readiness again.

## Maintenance commands (from repository root on authorized Windows operator PC)

Check function status:

```powershell
tccli --profile cvm-operator --region ap-singapore scf ListFunctions --Namespace hbd-dev
```

Verify HTTPS with CAM; both signed endpoints must return 200, anonymous requests must return 436:

```powershell
python -B infra/tencent/tools/cam_smoke.py --profile cvm-operator --expect-ready 200
```

Rotate DEV database URI (obtain the transaction pooler connection URI from **Supabase DEV**, port 6543; enter it in the hidden terminal prompt, never as a command argument):

```powershell
python -B infra/tencent/tools/configure_db.py --profile cvm-operator --check-only
python -B infra/tencent/tools/configure_db.py --profile cvm-operator
```

Rotate the trusted CA certificate, using the actual path to the PEM downloaded from **Supabase DEV → Database → SSL Configuration**. First command only validates Node `pg` TLS + `SELECT 1`; second updates SCF environment:

```powershell
python -B infra/tencent/tools/configure_tls_ca.py --profile cvm-operator --cert "$HOME\Downloads\prod-ca-2021.crt"
python -B infra/tencent/tools/configure_tls_ca.py --profile cvm-operator --cert "$HOME\Downloads\prod-ca-2021.crt" --apply
```

Wait for `Active` after configuration changes, then repeat authenticated smoke. CA-aware Fastify code must be deployed before expecting the CA variable to affect readiness. The standalone historical one-off packaging/upload scripts under the operator home are **not the repository-owned release pipeline**; use verified reviewed artifacts and documented immutable COS paths, preserving previous versions for rollback.

## Root-cause history (resolved)

On 2026-10-26, the SCF database readiness returned 503. The same DEV pooler URI on the operator computer resolved DNS and TCP, but Node `pg` failed `SELECT 1` with `SELF_SIGNED_CERT_IN_CHAIN`. After downloading the official CA, adding it to Prisma adapter TLS settings, and rebuilding/redeploying Fastify, signed readiness returned HTTP 200. The problem was TLS trust, **not** missing URI or a confirmed wrong password.

## Docker test and release artifact contract (2026-10-26)

- Docker Compose PostgreSQL 17 is a local/CI **test dependency only**; Fastify runs natively, and Supabase DEV/PROD remain managed providers.
- `pnpm run db:test:all` runs isolated schema migrations, SQL regression tests, and a Fastify → Prisma → Docker PostgreSQL integration test. The integration test refuses remote database targets and never writes to hosted Supabase.
- `.github/workflows/ci.yml` verifies these tests and builds the **SCF ZIP format** using `infra/tencent/tools/package_scf.py` with `scf_bootstrap`, bundled `dist`, and production pnpm dependencies. Manual `CI` dispatch on `main` uploads the ZIP plus SHA-256 checksum as a GitHub artifact (not COS), replacing the former Tencent preflight workflow. This proves **packaging readiness**, not a cloud deployment; Tencent DEV CD remains disabled pending least-privilege credentials and release/rollback automation.

## Still pending

1. Review, commit, and PR the local repository changes; no automatic merge.
2. Least-privilege Tencent DEV CI deploy identity and reviewed GitHub Actions deploy/rollback workflow.
3. User-facing HTTPS ingress and authentication (CAM Function URL is not a browser-compatible API contract).
4. Post-deployment observability, rate/scale testing, independent ongoing billing review and rollback rehearsal.
5. Update the stale `hbd-api-dev` provider metadata description, which still calls the runtime a pending bootstrap.

**References:** [Supabase Postgres connection modes](https://supabase.com/docs/guides/database/connecting-to-postgres), [Tencent Function URL](https://cloud.tencent.com/document/product/583/96100), [CI/CD safety](../../.github/TENCENT-SUPABASE-CD.md).
