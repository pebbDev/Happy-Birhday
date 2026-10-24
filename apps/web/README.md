# @happy-birthday/web — Vue frontend (planned)

This is a **pnpm workspace placeholder** for the future Vue + Vite frontend. There is no frontend source code or `dev` script yet.

Once implemented, the frontend may own UI, routing, view models, interaction state and generated API DTO types. It must not include Prisma, PostgreSQL credentials, provider secrets or backend domain authorization logic.

The intended backend is `@happy-birthday/api` (`../api/`). Currently only `GET /health/live` and `GET /health/ready` are implemented in Fastify.

When the Vue app is created, place it directly in `apps/web/`, not inside another nested `frontend/` directory.
