import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import FallingPetals from '../FallingPetals.vue'

describe('FallingPetals', () => {
  it('renders deterministic decorative petals using global motion presets', () => {
    const wrapper = mount(FallingPetals)
    expect(wrapper.get('[data-effect="falling-petals"]').attributes('aria-hidden')).toBe('true')
    const falling = wrapper.findAll('.motion-gentle-fall')
    expect(falling).toHaveLength(19)
    expect(wrapper.findAll('.motion-gentle-tumble')).toHaveLength(19)
    expect(wrapper.findAll('svg')).toHaveLength(19)
    expect(falling[0]?.attributes('data-fall-duration')).toBe('11')
    expect(falling[0]?.attributes('data-fall-drift')).toBe('-56')
    expect(falling[0]?.attributes('data-fall-scale')).toBe('0.56')
    expect(falling.filter((p) => p.classes().includes('max-[600px]:hidden'))).toHaveLength(8)
    expect(wrapper.html()).not.toContain('falling-petals__')
  })
})
