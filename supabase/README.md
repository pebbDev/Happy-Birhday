# PostgreSQL — Happy Birthday Platform

Supabase is used as the **managed PostgreSQL database**, not as the Fastify application runtime.

- `migrations/`: canonical, versioned database schema and SQL function history; do not delete or rebaseline.
- `tests/database/`: database invariants and regression SQL.
- `config.toml`: Supabase CLI database configuration without Edge Functions.

The Fastify API in `../apps/api/` uses Prisma infrastructure adapters. Generated Prisma schema/client mappings are derivative of database structure, not a second migration authority.

Local `.env.local`, `.env.integration.local`, `.temp/` and `.branches/` may exist for developer tooling; treat them as private machine-local state and never commit credentials. Archiving source files does not delete already deployed Supabase cloud functions or database objects.
