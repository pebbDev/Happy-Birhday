# Happy Birthday Diana — Advanced UI Architecture (C)

Status: Implementation scope for the shared UI system; Invitation-specific Figma artwork remains feature-owned. This is not a deployment or visual pixel-diff certification.

## Dependency direction

1. **Design primitives:** `src/app/styles/tokens/{colors,spacing,typography,depth,motion}.css` own canonical design values.
2. **Tailwind adapter:** `src/app/styles/tokens.css` maps CSS variables to Tailwind v4 namespaces via `@theme inline`. The unchanged primary PIN gradient and shadow are declared in the canonical `colors.css` and `depth.css` categories, not duplicated in the adapter. No legacy token aliases.
3. **CSS foundation:** `src/app/styles/main.css` imports Tailwind and tokens; `@layer base` contains HTML defaults and accessible focus behavior. It does **not** own component classes such as `.panel`, `.page`, or `.form-field`.
4. **UI components:** `src/components/ui/` owns common presentation and native semantics. `BaseButton` and `UiPanel` expose typed variants; `UiTextField` and `UiRangeField` expose `v-model`; `UiPageShell`, `UiHint`, `UiEyebrow` and `UiLink` provide semantic composition.
5. **Features:** `src/features/` owns business state, events, routing and one-off scene artwork. Components consume shared UI via props, slots, events and models—not by depending on global CSS selector names. Special Figma scene layout and interactive envelope/hold controls remain feature-owned; generic UI does not absorb their unique art geometry.

### Invitation feature content ownership

- `features/invitation/pages/InvitationPage.vue` is the single owner of Invitation copy, media resolution, and `/entry` navigation.
- Page-only static copy (name, age, tagline, Polaroid caption/alt and letter text) lives directly on the component tags in the `InvitationPage.vue` template. There is no page-level `content` object or `InvitationContent` wrapper type. Reusable contracts (`InvitationLetterContent`, `SceneLayer`, `InvitationAsset`, `InvitationHeroCardProps`, `InvitationPolaroidProps`) stay in `features/invitation/types/invitation.types.ts`.
- The `/` route renders `InvitationPage.vue` directly; the Page owns both route-level composition and navigation. There is no `InvitationScene.vue` pass-through. The Page arranges `InvitationHeroCard.vue`, `InvitationPolaroid.vue`, `BrotherLetter.vue`, two `InvitationArtLayers.vue` planes, and `FallingPetals.vue`. Components receive typed props and emit events.
- `BrotherLetter.vue` renders typed letter content with optional `teaser` and `body` slots; its dialog state and animation remain local. `HoldToEnter.vue` receives a required label and emits `completed`; its timer/progress remain local.
- The `/` route resolves directly to `InvitationPage.vue`, avoiding a contentless nested router view.
- `invitation.constants.ts` defines each artwork layer with semantic `id`, `figmaNodeId`, descriptive intent, `frame`, `plane`, responsive override, and optional motion/fetch priority. Figma IDs are traceability metadata, never runtime lookups or Vue keys. All types stay in `invitation.types.ts`.
- `INVITATION_LAYERS` is the only exported layer collection. `InvitationPage.vue` derives `backgroundLayers` and `foregroundLayers` once from each layer's `plane` field, preserving array order; the constants module does not export filtered subsets.
- `INVITATION_ASSETS` is a typed registry of reusable artwork objects: `{ id, description, src }`. Asset IDs identify image files, whereas layer IDs identify placements, so reusable artwork metadata is not duplicated. Renderers consume `.src`; descriptions are for developers, not accessible `alt` labels. The `InvitationAsset` type remains in `invitation.types.ts`.

## Styling contract

- Prefer semantic utilities (`bg-ui-surface`, `text-ui-accent`, `border-ui-border`, `rounded-ui-panel`).
- Register reusable values once in tokens and bridge; do not introduce duplicate hardcoded colors in generic UI components.
- Keep every Tailwind variant string statically discoverable, never build utility names by string concatenation.
- Keep default HTML selectors inside `@layer base`. Use no unlayered component rules; this prevents `font: inherit` from overriding `text-sm`/`text-lg` on buttons.
- Use accessible native elements; UI state enters through typed props or `v-model`; interactions return via events.
- Reduced motion remains supported through motion-v, CSS media preference and Tailwind `motion-reduce:` variants.
- Preserve the Invitation Figma visuals and the PIN form gradient while migrating generic app styling.

### Shared visual tokens

- Token names are reusable and purpose-based, e.g. --color-canvas-rose, --font-size-display-heading, --shadow-folded-card. The original visual values remain unchanged.

- Invitation visual tokens are categorized into existing files in src/app/styles/tokens/: colors.css (colors/gradients), depth.css (shadows/glow/blur), typography.css (font sizes/line heights/tracking), spacing.css (spacing/radii/stroke). motion.css retains shared animation durations/easing. The 1.1 line-height reuses the existing --line-height-tight. No separate Invitation token CSS file is needed.
- Invitation scenes, falling petals, and crown motion presets **consume** tokens rather than declaring colors or custom typographic values locally; gradient/shadow tokens reference palette tokens.
- One-off Figma position coordinates and SVG path geometry remain local layout instructions, not global theme tokens.
- `InvitationTokenContract.test.ts` checks unique names, palette values, reference resolution and no raw component colors/gradients.
- Verify multi-layer backgrounds in a real browser; CSS `background` shorthand and `background-image` have different behavior.

## Change validation

Run `pnpm --filter @happy-birthday/web test`, `pnpm --filter @happy-birthday/web lint`, `pnpm --filter @happy-birthday/web build`, and the focused UI component tests. Confirm computed typography, semantic colors and primary gradient in a real browser for styling changes. Build passing alone does not prove pixel-perfect Figma parity.
