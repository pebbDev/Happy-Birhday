import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { afterEach, describe, expect, it, vi } from 'vitest'
import HoldToEnter from '../components/HoldToEnter.vue'

afterEach(() => vi.useRealTimers())

describe('HoldToEnter', () => {
  it('uses a subtle track and a strong purple progress stroke', () => {
    const wrapper = mount(HoldToEnter, { props: { label: 'Hold to enter' } })
    expect(wrapper.get('.hold-progress-track').attributes('stroke')).toBe(
      'var(--color-press-control-track)',
    )
    expect(wrapper.get('.hold-progress-track').attributes('stroke-opacity')).toBe('0.2')
    expect(wrapper.get('.hold-progress-ring').attributes('stroke')).toBe(
      'var(--color-press-control-progress)',
    )
    expect(wrapper.get('.hold-progress').classes()).toContain(
      '[&_circle]:[stroke-width:var(--stroke-width-progress)]',
    )
    wrapper.unmount()
  })

  it('draws the circumference during hold, cancels cleanly, and reaches 100% only on completion', async () => {
    vi.useFakeTimers()
    const wrapper = mount(HoldToEnter, { props: { label: 'Hold to enter' } })
    const button = wrapper.get('[data-action="hold-enter"]')
    const ring = wrapper.get('.hold-progress-ring')
    const circumference = Number(ring.attributes('stroke-dasharray'))
    const offset = () => Number(ring.attributes('stroke-dashoffset'))

    expect(offset()).toBeCloseTo(circumference)
    await button.trigger('pointerdown', { isPrimary: true })
    await vi.advanceTimersByTimeAsync(425)
    await nextTick()
    expect(offset()).toBeGreaterThan(0)
    expect(offset()).toBeLessThan(circumference)
    expect(wrapper.emitted('completed')).toBeUndefined()

    await button.trigger('pointerup')
    await nextTick()
    expect(offset()).toBeCloseTo(circumference)
    await vi.advanceTimersByTimeAsync(500)
    expect(wrapper.emitted('completed')).toBeUndefined()

    await button.trigger('pointerdown', { isPrimary: true })
    await vi.advanceTimersByTimeAsync(850)
    await nextTick()
    expect(offset()).toBe(0)
    expect(wrapper.emitted('completed')).toHaveLength(1)
    wrapper.unmount()
  })

  it('requires 850ms pointer hold and cancels on early release', async () => {
    vi.useFakeTimers()
    const wrapper = mount(HoldToEnter, { props: { label: 'Hold to enter' } })
    const button = wrapper.get('[data-action="hold-enter"]')
    await button.trigger('pointerdown', { isPrimary: true })
    await vi.advanceTimersByTimeAsync(849)
    expect(wrapper.emitted('completed')).toBeUndefined()
    await button.trigger('pointerup')
    await vi.advanceTimersByTimeAsync(100)
    expect(wrapper.emitted('completed')).toBeUndefined()
    await button.trigger('pointerdown', { isPrimary: true })
    await vi.advanceTimersByTimeAsync(850)
    expect(wrapper.emitted('completed')?.length).toBe(1)
  })

  it('renders a page-provided label and updates accessibility text reactively', async () => {
    const wrapper = mount(HoldToEnter, { props: { label: 'Start the journey' } })
    expect(wrapper.get('.hold-label').text()).toBe('Start the journey')
    expect(wrapper.get('[data-action="hold-enter"]').attributes('aria-label')).toContain(
      'Start the journey',
    )
    await wrapper.setProps({ label: 'Continue' })
    expect(wrapper.get('.hold-label').text()).toBe('Continue')
    wrapper.unmount()
  })

  it('supports Enter and Space on the primary button without a long hold', async () => {
    const wrapper = mount(HoldToEnter, { props: { label: 'Hold to enter' } })
    const button = wrapper.get('[data-action="hold-enter"]')
    expect(button.attributes('aria-label')).toMatch(/hold to enter/i)
    await button.trigger('keydown.enter')
    await button.trigger('keydown.space')
    expect(wrapper.emitted('completed')?.length).toBe(2)
    expect(wrapper.find('[data-action="hold-enter-alternative"]').exists()).toBe(false)
  })
})
