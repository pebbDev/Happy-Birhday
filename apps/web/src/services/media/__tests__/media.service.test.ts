import { afterEach, describe, expect, it, vi } from 'vitest'
import { MEDIA_CATALOG } from '../media.constants'
import { fallbackMediaSrc, resolveMediaSrc, setPrivateMediaUrlProvider } from '../media.service'

const mediaId = 'invitation-polaroid' as const
const publicFallback = '/backgrounds/invitation/hero-landscape.webp'

function inBrowserWithHost(hostname: string) {
  vi.stubGlobal('window', { location: { hostname } })
}

afterEach(() => {
  setPrivateMediaUrlProvider(null)
  vi.unstubAllGlobals()
})

describe('shared media resolver', () => {
  it('exposes the public SSR-safe fallback and typed media catalog', () => {
    expect(MEDIA_CATALOG[mediaId].kind).toBe('image')
    expect(MEDIA_CATALOG[mediaId].access).toBe('private')
    expect(fallbackMediaSrc(mediaId)).toBe(publicFallback)
  })

  it('never resolves private media during SSR', async () => {
    vi.stubGlobal('window', undefined)
    const provider = vi.fn(async () => 'https://cos.example.test/private.webp?temporary=1')
    setPrivateMediaUrlProvider(provider)

    expect(await resolveMediaSrc(mediaId)).toBe(publicFallback)
    expect(provider).not.toHaveBeenCalled()
  })

  it('shows the ignored local preview only on a development loopback hostname', async () => {
    inBrowserWithHost('127.0.0.1')
    expect(await resolveMediaSrc(mediaId)).toBe('/__local_preview/photo-0661.webp')
    inBrowserWithHost('localhost')
    expect(await resolveMediaSrc(mediaId)).toBe('/__local_preview/photo-0661.webp')
  })

  it('obtains a temporary private URL through a registered provider on other hosts', async () => {
    inBrowserWithHost('birthday.example.test')
    const temporaryUrl = 'https://cos.example.test/private.webp?sign=temporary'
    const provider = vi.fn(async () => temporaryUrl)
    setPrivateMediaUrlProvider(provider)

    expect(await resolveMediaSrc(mediaId)).toBe(temporaryUrl)
    expect(provider).toHaveBeenCalledExactlyOnceWith(mediaId)
  })

  it('fails back to safe public artwork if no authorized provider exists or it fails', async () => {
    inBrowserWithHost('birthday.example.test')
    expect(await resolveMediaSrc(mediaId)).toBe(publicFallback)

    const provider = vi.fn(async () => {
      throw new Error('not authorized')
    })
    setPrivateMediaUrlProvider(provider)
    expect(await resolveMediaSrc(mediaId)).toBe(publicFallback)
  })

  it('rejects plain HTTP and empty URLs from the provider', async () => {
    inBrowserWithHost('birthday.example.test')
    setPrivateMediaUrlProvider(async () => 'http://cos.example.test/private.webp')
    expect(await resolveMediaSrc(mediaId)).toBe(publicFallback)
    setPrivateMediaUrlProvider(async () => null)
    expect(await resolveMediaSrc(mediaId)).toBe(publicFallback)
  })
})
