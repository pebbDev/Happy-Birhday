import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import {
  MEDIA_PLAYBACK_DEFAULTS,
  MEDIA_VOLUME_MAX,
  MEDIA_VOLUME_MIN,
} from '../constants/mediaPlayback.constants'
import type { MediaPlaybackPreferences } from '../types/mediaPlayback.types'

/**
 * Shared preferences only. Video streams, signed COS URLs and auth tokens
 * belong in the media delivery service, never the Pinia state.
 */
export const useMediaPlaybackStore = defineStore('media-playback-demo', () => {
  const muted = ref<boolean>(MEDIA_PLAYBACK_DEFAULTS.muted)
  const volume = ref<number>(MEDIA_PLAYBACK_DEFAULTS.volume)
  const effectiveVolume = computed(() => (muted.value ? 0 : volume.value))

  function setVolume(value: number): void {
    if (!Number.isFinite(value)) return
    volume.value = Math.max(MEDIA_VOLUME_MIN, Math.min(MEDIA_VOLUME_MAX, Math.round(value)))
  }

  function toggleMuted(): void {
    muted.value = !muted.value
  }

  function applyPreferences(next: MediaPlaybackPreferences): void {
    muted.value = next.muted
    setVolume(next.volume)
  }

  function reset(): void {
    applyPreferences(MEDIA_PLAYBACK_DEFAULTS)
  }

  // Return ALL reactive state for Pinia DevTools and SSR compatibility.
  return { muted, volume, effectiveVolume, setVolume, toggleMuted, applyPreferences, reset }
})
