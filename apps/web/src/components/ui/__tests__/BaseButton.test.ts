import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import BaseButton from '../BaseButton.vue'

describe('BaseButton design-system variants', () => {
  it('preserves the existing default button semantics and visual class', () => {
    const wrapper = mount(BaseButton, { slots: { default: 'Buka Birthday World' } })
    const button = wrapper.get('button')
    expect(button.attributes('type')).toBe('button')
    expect(button.text()).toBe('Buka Birthday World')
    expect(button.classes()).toContain('min-h-12')
    expect(button.classes()).toContain('border-0')
    expect(button.classes()).toContain('duration-[var(--motion-duration-fast)]')
    expect(button.classes()).toContain('motion-reduce:transition-none')
    expect(button.attributes('disabled')).toBeUndefined()
    wrapper.unmount()
  })

  it.each([
    ['primary', 'md', 'border-0', 'min-h-12'],
    ['secondary', 'sm', 'bg-ui-surface-raised', 'min-h-10'],
    ['ghost', 'lg', 'text-ui-accent', 'min-h-14'],
  ] as const)(
    'applies %s/%s as static semantic classes',
    (variant, size, visualClass, sizingClass) => {
      const wrapper = mount(BaseButton, { props: { variant, size } })
      const button = wrapper.get('button')
      expect(button.classes()).toContain(visualClass)
      expect(button.classes()).toContain(sizingClass)
      wrapper.unmount()
    },
  )

  it('reactively updates variant, size, button type and disabled state', async () => {
    const wrapper = mount(BaseButton, { props: { variant: 'primary', size: 'sm' } })
    const button = wrapper.get('button')

    await wrapper.setProps({ variant: 'ghost', size: 'lg', type: 'reset', disabled: true })

    expect(button.classes()).toContain('text-ui-accent')
    expect(button.classes()).toContain('min-h-14')
    expect(button.classes()).not.toContain('border-0')
    expect(button.classes()).not.toContain('min-h-10')
    expect(button.attributes('type')).toBe('reset')
    expect(button.attributes('disabled')).toBeDefined()

    await wrapper.setProps({ disabled: false })
    expect(button.attributes('disabled')).toBeUndefined()
    wrapper.unmount()
  })

  it('uses native disabled and submit semantics without forwarding click events', async () => {
    const wrapper = mount(BaseButton, {
      props: { type: 'submit', disabled: true, variant: 'secondary' },
    })
    const button = wrapper.get('button')
    expect(button.attributes('type')).toBe('submit')
    expect(button.attributes('disabled')).toBeDefined()
    await button.trigger('click')
    expect(wrapper.emitted('click')).toBeUndefined()
    wrapper.unmount()
  })
})
