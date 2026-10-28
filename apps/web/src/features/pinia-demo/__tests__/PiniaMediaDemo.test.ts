import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { describe, expect, it } from 'vitest'
import PiniaMediaDemoScene from '../components/PiniaMediaDemoScene.vue'

describe('Pinia demo components', () => {
  it('shares one reactive store between sibling components', async () => {
    const wrapper = mount(PiniaMediaDemoScene, {
      global: { plugins: [createPinia()] },
    })

    expect(wrapper.get('[data-testid="effective-volume"]').text()).toContain('65%')
    await wrapper.get('[data-testid="toggle-mute"]').trigger('click')
    expect(wrapper.get('[data-testid="muted-status"]').text()).toBe('Muted')
    expect(wrapper.get('[data-testid="effective-volume"]').text()).toContain('0%')

    await wrapper.get('[data-testid="volume-input"]').setValue('37')
    expect(wrapper.get('[data-testid="volume-label"]').text()).toBe('37')
    await wrapper.get('[data-testid="toggle-mute"]').trigger('click')
    expect(wrapper.get('[data-testid="effective-volume"]').text()).toContain('37%')

    await wrapper.get('[data-testid="reset-media"]').trigger('click')
    expect(wrapper.get('[data-testid="effective-volume"]').text()).toContain('65%')
    wrapper.unmount()
  })

  it('server-renders reproducible default preferences with per-app Pinia', async () => {
    const render = () => {
      const app = createSSRApp(PiniaMediaDemoScene)
      app.use(createPinia())
      return renderToString(app)
    }
    const [first, second] = await Promise.all([render(), render()])
    expect(first).toContain('65%')
    expect(first).toContain('Sound enabled')
    expect(first).toBe(second)
    await flushPromises()
  })
})
