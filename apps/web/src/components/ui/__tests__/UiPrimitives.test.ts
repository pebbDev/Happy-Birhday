import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import UiEyebrow from '../UiEyebrow.vue'
import UiHint from '../UiHint.vue'
import UiPageShell from '../UiPageShell.vue'
import UiPanel from '../UiPanel.vue'
import UiRangeField from '../UiRangeField.vue'
import UiTextField from '../UiTextField.vue'

describe('Advanced UI design-system contracts', () => {
  it('composes semantic page, surface, eyebrow, and status primitives', () => {
    const page = mount(UiPageShell, { slots: { default: 'Page content' } })
    expect(page.element.tagName).toBe('MAIN')
    expect(page.text()).toContain('Page content')
    const panel = mount(UiPanel, {
      props: { as: 'section', tone: 'raised', padding: 'lg' },
      slots: { default: 'Surface content' },
    })
    expect(panel.element.tagName).toBe('SECTION')
    expect(panel.classes()).toContain('bg-ui-surface-raised')
    expect(panel.classes()).toContain('p-8')
    expect(panel.text()).toContain('Surface content')

    const eyebrow = mount(UiEyebrow, { slots: { default: 'Private access' } })
    expect(eyebrow.element.tagName).toBe('P')
    expect(eyebrow.classes()).toContain('text-ui-accent')
    const hint = mount(UiHint, { attrs: { role: 'status' }, slots: { default: 'Pending' } })
    expect(hint.attributes('role')).toBe('status')
    expect(hint.text()).toBe('Pending')
  })

  it('updates panel variants reactively', async () => {
    const panel = mount(UiPanel)
    expect(panel.classes()).toContain('bg-ui-surface')
    await panel.setProps({ tone: 'raised', padding: 'sm' })
    expect(panel.classes()).toContain('bg-ui-surface-raised')
    expect(panel.classes()).toContain('p-4')
    expect(panel.classes()).not.toContain('bg-ui-surface')
  })

  it('provides native accessible PIN field and emits v-model updates', async () => {
    const field = mount(UiTextField, {
      props: {
        label: 'Shared PIN',
        name: 'pin',
        modelValue: '',
        type: 'password',
        inputmode: 'numeric',
        required: true,
        placeholder: 'Masukkan PIN',
      },
    })
    const input = field.get('input')
    expect(field.get('label').text()).toBe('Shared PIN')
    expect(input.attributes('name')).toBe('pin')
    expect(input.attributes('type')).toBe('password')
    expect(input.attributes('inputmode')).toBe('numeric')
    expect(input.attributes('required')).toBeDefined()
    await input.setValue('2468')
    expect(field.emitted('update:modelValue')?.at(-1)).toEqual(['2468'])
  })

  it('emits numeric range updates while keeping input accessible', async () => {
    const range = mount(UiRangeField, {
      props: { label: 'Volume', inputTestId: 'volume-input', modelValue: 65 },
    })
    expect(range.get('label').text()).toContain('Volume')
    const input = range.get('[data-testid="volume-input"]')
    expect(input.attributes('type')).toBe('range')
    await input.setValue('37')
    expect(range.emitted('update:modelValue')?.at(-1)).toEqual([37])
  })
})
