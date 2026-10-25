# @happy-birthday/web — Vue frontend starter

**Scope:** frontend boilerplate with build-time public Invitation prerendering and neutral CSR fallback. Protected journeys, auth APIs, and browser deployment verification remain incomplete.

## Stack

Vue 3, Vite, TypeScript, Vue Router, Composition API / `<script setup>`, Vitest + Vue Test Utils, ESLint.

## Workspace setup

From **repository root**, use the already-pinned `pnpm@12.15.0` and the supported Node runtime. This starter does **not** bring another lockfile.

```sh
pnpm install
pnpm --filter @happy-birthday/web dev
pnpm --filter @happy-birthday/web typecheck
pnpm --filter @happy-birthday/web lint
pnpm --filter @happy-birthday/web test
pnpm --filter @happy-birthday/web build
```

Local validation completed with Node.js 24.22.1 and pnpm 12.15.0. The root workspace lockfile has been updated and a frozen offline install passes; minimum supported Node versions still need to be validated across CI and deployment.

## Structure

- `src/app`: root Vue component, router, global styles.
- `src/features`: invitation, protected-entry, birthday-world, photo-booth, async-together, memories.
- `src/components`: shared presentational UI; feature-specific pieces stay in their feature.
- `src/composables`: cross-feature Vue reactive behavior.
- `src/lib`: public environment config and generic HTTP helper.
- `src/assets`: build-managed **public-safe** assets only.

## Safety boundary

Only Public Invitation is public. Routes `/world`, `/photo-booth`, `/together`, `/memories` are **placeholders only**, showing zero private content. Router guards alone are not authorization. The PIN form does **not** fake access; authentication integration is blocked until Fastify's business API endpoints are implemented. Do not embed protected narratives, photos, secrets, or shared PIN in frontend assets or source.

## Rendering: Selective SSG + CSR (ACCEPTED)

- Production build uses the official Vite SSR module-loading API and Vue server renderer to prerender only the public Invitation at `dist/index.html`. Initial HTML is hydrated with `createSSRApp`.
- The neutral, non-prerendered `dist/spa.html` is used for all other direct URLs via `vercel.json`'s filesystem-first rewrite. Vue client-mounts these routes with `createApp`; navigations within the app use Vue Router history mode.
- Build includes extracted Invitation CSS in the prerendered HTML so initial styling does not wait for hydration. `pnpm --filter @happy-birthday/web test:rendering` verifies generated output.
- Protected routes contain only public-safe placeholders until the Fastify PIN, authorization and media APIs exist. No private data are embedded in HTML or JS bundles.
- **Pending:** Verify real Vercel Preview routing, browser hydration/no-mismatch, direct deep links, mobile performance and access-control integration. SSG output and browser behavior are distinct verification axes.

## Implementation / validation checklist

- [x] Integrate boilerplate into the local monorepo on branch `feat/web-vue-foundation` (not committed or pushed).
- [ ] Review future package upgrades against official `create-vue` release compatibility.
- [x] Refresh the single root `pnpm-lock.yaml` and verify `pnpm install --frozen-lockfile --offline`.
- [ ] Validate supported minimum Node engine requirements across local development, CI and deployment (local Node 24 works).
- [x] Verify local typecheck, lint, Vitest (initial test) and Vite production build.
- [ ] Add frontend PR CI as a required workflow/check.
- [x] Implement selective Invitation SSG build and neutral CSR fallback; validate generated static HTML.
- [ ] Verify hydration and protected-route direct URLs end-to-end on Vercel Preview.
- [ ] Implement Fastify PIN/access APIs and frontend integration before exposing protected routes to real users.
- [ ] Verify direct deep links, invitation destination continuity, mobile Core Web Vitals, reduced-motion UX, and privacy.
- [ ] Deploy Preview only after verifying build and hosting behavior.