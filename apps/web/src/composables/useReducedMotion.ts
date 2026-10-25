import { onMounted, onUnmounted, ref } from 'vue'

export function useReducedMotion() {
  const prefersReducedMotion = ref(false)
  let query: MediaQueryList | undefined
  const refresh = () => {
    prefersReducedMotion.value = query?.matches ?? false
  }

  onMounted(() => {
    query = window.matchMedia('(prefers-reduced-motion: reduce)')
    refresh()
    query.addEventListener('change', refresh)
  })
  onUnmounted(() => query?.removeEventListener('change', refresh))
  return { prefersReducedMotion }
}