import { flushPromises, mount } from '@vue/test-utils'
import { createMemoryHistory, createRouter } from 'vue-router'
import { describe, expect, it } from 'vitest'
import App from '@/app/App.vue'
import { routes } from '../routes'
import { PENDING_PAGE_COPY } from '../pageContent.constants'

async function renderAt(path: string) {
  const router = createRouter({ history: createMemoryHistory(), routes })
  await router.push(path)
  await router.isReady()
  const wrapper = mount(App, { global: { plugins: [router] } })
  await flushPromises()
  return { wrapper, router }
}

describe('Native Vue Router page composition', () => {
  it('renders the protected entry scene via a template-only parent page', async () => {
    const { wrapper, router } = await renderAt('/entry')
    expect(router.currentRoute.value.name).toBe('protected-entry')
    expect(wrapper.text()).toContain('Welcome in.')
    expect(wrapper.find('form input[name="pin"]').exists()).toBe(true)
    wrapper.unmount()
  })

  it.each([
    ['/world', 'birthday-world'],
    ['/photo-booth', 'photo-booth'],
    ['/together/some-invite', 'async-together'],
    ['/memories', 'memory-wall'],
  ] as const)('renders %s through the native nested route', async (path, name) => {
    const { wrapper, router } = await renderAt(path)
    expect(router.currentRoute.value.name).toBe(name)
    expect(wrapper.find('h1').text()).toBe(PENDING_PAGE_COPY[name].title)
    expect(wrapper.text()).toContain(PENDING_PAGE_COPY[name].explanation)
    expect(wrapper.find('a[href="/entry"]').exists()).toBe(true)
    if (name === 'async-together') {
      expect(router.currentRoute.value.params.inviteId).toBe('some-invite')
    }
    wrapper.unmount()
  })

  it('keeps the same Async Together component reactive across inviteId changes', async () => {
    const { wrapper, router } = await renderAt('/together/first-invite')
    const currentContext = wrapper.get('[data-role="invite-route-context"]')
    const sameElement = currentContext.element
    expect(currentContext.attributes('data-invite-id')).toBe('first-invite')
    expect(currentContext.text()).toContain('Tautan undangan telah dikenali')

    await router.push('/together/second-invite')
    await flushPromises()
    expect(router.currentRoute.value.params.inviteId).toBe('second-invite')
    expect(wrapper.get('[data-role="invite-route-context"]').element).toBe(sameElement)
    expect(wrapper.get('[data-role="invite-route-context"]').attributes('data-invite-id')).toBe(
      'second-invite',
    )
    expect(wrapper.html()).not.toContain('first-invite')

    await router.push('/together')
    await flushPromises()
    expect(wrapper.get('[data-role="invite-route-context"]').attributes('data-invite-id')).toBe(
      undefined,
    )
    expect(wrapper.get('[data-role="invite-route-context"]').text()).toContain(
      'Tautan belum menyertakan ID undangan',
    )
    wrapper.unmount()
  })

  it('preserves a not-found route with a working invitation link', async () => {
    const { wrapper, router } = await renderAt('/route-does-not-exist')
    expect(router.currentRoute.value.name).toBe('not-found')
    expect(wrapper.text()).toContain('Halaman tidak ditemukan')
    expect(wrapper.find('a[href="/"]').exists()).toBe(true)
    wrapper.unmount()
  })
})
