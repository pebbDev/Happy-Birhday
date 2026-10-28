import { beforeEach, describe, expect, it } from 'vitest'
import { createPinia, setActivePinia, storeToRefs } from 'pinia'
import { useMediaPlaybackStore } from '../stores/useMediaPlaybackStore'

beforeEach(() => setActivePinia(createPinia()))

describe('Pinia media playback preferences', () => {
  it('exposes all setup state for DevTools and SSR; never stores media secrets', () => {
    const store = useMediaPlaybackStore()
    expect(store.$state).toEqual({ muted: false, volume: 65 })
    expect(Object.keys(store.$state).sort()).toEqual(['muted', 'volume'])
    expect(JSON.stringify(store.$state)).not.toMatch(/cos|signed|token|url/i)
  })

  it('uses storeToRefs to keep getters and state reactive after destructuring', () => {
    const store = useMediaPlaybackStore()
    const { muted, volume, effectiveVolume } = storeToRefs(store)
    const { toggleMuted, setVolume } = store

    setVolume(37)
    expect(volume.value).toBe(37)
    expect(effectiveVolume.value).toBe(37)
    toggleMuted()
    expect(muted.value).toBe(true)
    expect(effectiveVolume.value).toBe(0)
    toggleMuted()
    expect(effectiveVolume.value).toBe(37)
  })

  it('validates volume and preserves a consistent, safe range', () => {
    const store = useMediaPlaybackStore()
    store.setVolume(145)
    expect(store.volume).toBe(100)
    store.setVolume(-11)
    expect(store.volume).toBe(0)
    store.setVolume(Number.NaN)
    expect(store.volume).toBe(0)
    store.applyPreferences({ muted: true, volume: 45.8 })
    expect(store.$state).toEqual({ muted: true, volume: 46 })
    store.reset()
    expect(store.$state).toEqual({ muted: false, volume: 65 })
  })

  it('creates isolated state for independent app/SSR instances', () => {
    const first = createPinia()
    const second = createPinia()
    const firstStore = useMediaPlaybackStore(first)
    const secondStore = useMediaPlaybackStore(second)
    firstStore.applyPreferences({ muted: true, volume: 2 })
    expect(secondStore.$state).toEqual({ muted: false, volume: 65 })
  })
})
