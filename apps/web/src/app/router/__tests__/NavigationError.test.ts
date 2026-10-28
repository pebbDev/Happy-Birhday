import { nextTick, shallowRef } from 'vue'
import { mount } from '@vue/test-utils'
import App from '@/app/App.vue'
import { createRouter, createMemoryHistory } from 'vue-router'
import { describe, expect, it, vi } from 'vitest'
import { mountWhenRouterReady } from '../mount-when-ready'
import { NAVIGATION_ERROR_KEY, registerNavigationErrorHandling } from '../navigation-error'

describe('navigation failures', () => {
  it('waits for initial async navigation before mounting', async () => {
    let finishReady!: () => void
    const ready = new Promise<void>((resolve) => {
      finishReady = resolve
    })
    const mount = vi.fn()
    const onError = vi.fn()
    const startup = mountWhenRouterReady({ isReady: () => ready }, mount, onError)
    expect(mount).not.toHaveBeenCalled()
    finishReady()
    await startup
    expect(mount).toHaveBeenCalledOnce()
    expect(onError).not.toHaveBeenCalled()
  })

  it('handles rejected isReady without leaving a blank application', async () => {
    const error = new Error('route import failed')
    const onError = vi.fn()
    const mount = vi.fn()
    await expect(
      mountWhenRouterReady(
        {
          isReady: async () => {
            throw error
          },
        },
        mount,
        onError,
      ),
    ).resolves.toBeUndefined()
    expect(onError).toHaveBeenCalledExactlyOnceWith(error)
    expect(mount).toHaveBeenCalledOnce()
  })

  it('shows an accessible reload notice when navigation fails and hides it on recovery', async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [{ path: '/', component: { template: '<p>Ready</p>' } }],
    })
    await router.push('/')
    await router.isReady()
    const hasError = shallowRef(true)
    const wrapper = mount(App, {
      global: {
        plugins: [router],
        provide: { [NAVIGATION_ERROR_KEY]: hasError },
      },
    })

    expect(wrapper.get('[data-testid="navigation-error"]').attributes('role')).toBe('alert')
    expect(wrapper.get('[data-testid="navigation-error"]').text()).toContain('Muat ulang')
    hasError.value = false
    await nextTick()
    expect(wrapper.find('[data-testid="navigation-error"]').exists()).toBe(false)
    wrapper.unmount()
  })

  it('reports lazy-route failures, and clears the error after a successful navigation', async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/broken', component: () => Promise.reject(new Error('chunk unavailable')) },
        { path: '/good', component: { template: '<p>OK</p>' } },
      ],
    })
    const hasError = shallowRef(false)
    const report = vi.fn()
    registerNavigationErrorHandling(router, hasError, report)
    await expect(router.push('/broken')).rejects.toThrow('chunk unavailable')
    expect(hasError.value).toBe(true)
    expect(report).toHaveBeenCalledOnce()

    await router.push('/good')
    await router.isReady()
    expect(hasError.value).toBe(false)
  })
})
