# @happy-birthday/contracts

This pnpm workspace contains the **active** `openapi/openapi.yaml` contract for Fastify.

Right now it describes only implemented Fastify health endpoints. The earlier extended Deno/Supabase Edge draft was archived externally and is **not** an implemented production API.

When `@happy-birthday/web` begins consuming API types, add a single explicit OpenAPI-to-TypeScript generation workflow to this package and expose generated types. Do not share Prisma models, database credentials or backend rich domain entities with browser code.

No generated API types or fictitious business DTOs have been created.
