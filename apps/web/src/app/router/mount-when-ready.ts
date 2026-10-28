import type { Router } from 'vue-router'

/**
 * Wait for initial lazy route resolution before Vue mount/hydration.
 * When resolution fails, still mount the app to display the error notice.
 * Never silently discard router.isReady() rejections.
 */
export async function mountWhenRouterReady(
  router: Pick<Router, 'isReady'>,
  mount: () => void,
  onNavigationError: (error: unknown) => void,
): Promise<void> {
  try {
    await router.isReady()
  } catch (error) {
    onNavigationError(error)
  }
  mount()
}
