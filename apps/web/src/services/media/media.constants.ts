import type { MediaDefinition } from './media.types'

/**
 * Media IDs are logical UI references, not COS object keys or secret URLs.
 * Private media are never placed in public/ or bundled into production.
 * The catalog can grow to support both photos and videos.
 */
export const MEDIA_CATALOG = {
  'invitation-polaroid': {
    kind: 'image',
    access: 'private',
    fallbackSrc: '/backgrounds/invitation/hero-landscape.webp',
  },
} as const satisfies Record<string, MediaDefinition>

export type MediaId = keyof typeof MEDIA_CATALOG
