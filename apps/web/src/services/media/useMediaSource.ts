import { onMounted, onUnmounted, shallowRef } from 'vue'
import { fallbackMediaSrc, resolveMediaSrc } from './media.service'
import type { MediaId } from './media.constants'

/** SSR-safe media reference; resolves private media only after browser mount. */
export function useMediaSource(id: MediaId) {
  const src = shallowRef<string>(fallbackMediaSrc(id))
  let alive = true

  onMounted(() => {
    void resolveMediaSrc(id).then((url) => {
      if (alive) src.value = url
    })
  })
  onUnmounted(() => {
    alive = false
  })

  return { src }
}
