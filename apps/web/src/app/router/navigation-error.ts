import type { InjectionKey, ShallowRef } from 'vue'
import type { Router } from 'vue-router'

/** Injected per app, avoiding cross-request state sharing during SSR. */
export const NAVIGATION_ERROR_KEY: InjectionKey<ShallowRef<boolean>> = Symbol('navigation-error')

export function registerNavigationErrorHandling(
  router: Pick<Router, 'onError' | 'afterEach'>,
  hasError: ShallowRef<boolean>,
  report: (error: unknown) => void,
): void {
  router.onError((error) => {
    hasError.value = true
    report(error)
  })
  router.afterEach((_to, _from, failure) => {
    // Only successful navigation clears a previously shown error.
    if (!failure) hasError.value = false
  })
}
