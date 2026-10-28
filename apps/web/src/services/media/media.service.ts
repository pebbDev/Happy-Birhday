import { MEDIA_CATALOG, type MediaId } from './media.constants'
import type { MediaDefinition, PrivateMediaUrlProvider } from './media.types'

// Production provider is intentionally NOT registered until the authenticated
// Fastify/COS temporary-URL endpoint is implemented and its access policy verified.
let privateMediaUrlProvider: PrivateMediaUrlProvider | null = null

export function setPrivateMediaUrlProvider(provider: PrivateMediaUrlProvider | null): void {
  privateMediaUrlProvider = provider
}

function isLocalDevelopment(): boolean {
  return (
    import.meta.env.DEV &&
    typeof window !== 'undefined' &&
    ['localhost', '127.0.0.1'].includes(window.location.hostname)
  )
}

export function fallbackMediaSrc(id: MediaId): string {
  return MEDIA_CATALOG[id].fallbackSrc
}

/**
 * The same API resolves photos and videos.
 * Never expose COS credentials, permanent public access, or private object keys.
 */
export async function resolveMediaSrc(id: MediaId): Promise<string> {
  const media: MediaDefinition = MEDIA_CATALOG[id]
  if (media.access === 'public') {
    return media.publicSrc ?? media.fallbackSrc
  }

  if (import.meta.env.DEV && isLocalDevelopment()) {
    // Vite must eliminate this entire branch from public production bundles.
    // Do not dynamically import a dev-only file: Vite will still emit its chunk.
    const localPreviewById: Partial<Record<MediaId, string>> = {
      'invitation-polaroid': '/__local_preview/photo-0661.webp',
    }
    const preview = localPreviewById[id]
    if (preview) return preview
  }

  if (privateMediaUrlProvider && typeof window !== 'undefined') {
    try {
      // Provider must enforce authentication/authorization server-side.
      const url = await privateMediaUrlProvider(id)
      if (url && /^https:\/\//.test(url)) return url
    } catch {
      // Fail closed to a public fallback; never print private URL or identity.
    }
  }
  return media.fallbackSrc
}
