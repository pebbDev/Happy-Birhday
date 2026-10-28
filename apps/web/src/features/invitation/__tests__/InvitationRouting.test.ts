import { flushPromises, mount } from '@vue/test-utils'
import { createMemoryHistory, createRouter } from 'vue-router'
import { describe, expect, it, vi } from 'vitest'
import App from '@/app/App.vue'
import { routes } from '@/app/router/routes'

describe('Invitation page route', () => {
  it('composes the Invitation directly in the page and enters the PIN route', async () => {
    const router = createRouter({ history: createMemoryHistory(), routes })
    await router.push('/')
    await router.isReady()

    const wrapper = mount(App, { global: { plugins: [router] } })
    await flushPromises()

    expect(router.currentRoute.value.name).toBe('invitation')
    expect(wrapper.find('[data-scene="invitation"]').exists()).toBe(true)
    expect(wrapper.findAll('img[data-figma-node]')).toHaveLength(21)
    const navigate = vi.spyOn(router, 'push')
    await wrapper.get('[data-action="hold-enter"]').trigger('keydown.enter')
    await flushPromises()
    expect(navigate).toHaveBeenCalledWith('/entry')
    await navigate.mock.results[0]?.value
    await flushPromises()
    expect(router.currentRoute.value.name).toBe('protected-entry')
    expect(wrapper.find('input[name="pin"]').exists()).toBe(true)
    wrapper.unmount()
  })
})
