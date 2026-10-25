import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import InvitationPage from '../pages/InvitationPage.vue'

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: vi.fn() }),
}))

describe('InvitationPage', () => {
  it('renders only public-safe text and an entry interaction', () => {
    const wrapper = mount(InvitationPage)
    expect(wrapper.text()).toContain('A special invitation')
    expect(wrapper.text()).toContain('Tahan untuk masuk')
    expect(wrapper.text()).not.toContain('private photo')
  })
})