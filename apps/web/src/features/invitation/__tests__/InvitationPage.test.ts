import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import InvitationPage from '../pages/InvitationPage.vue'
import InvitationHeroCard from '../components/InvitationHeroCard.vue'
import InvitationPolaroid from '../components/InvitationPolaroid.vue'
import BrotherLetter from '../components/BrotherLetter.vue'
import { INVITATION_ASSETS, INVITATION_LAYERS } from '../constants/invitation.constants'

const push = vi.fn()
vi.mock('vue-router', () => ({
  useRouter: () => ({ push }),
}))

describe('Invitation direct page composition and visual components', () => {
  it('renders Diana 28 with local project typography and original Figma scene layers', () => {
    expect(INVITATION_LAYERS).toHaveLength(17)
    const wrapper = mount(InvitationPage)
    expect(wrapper.find('h1').text()).toMatch(/DIANA\s*28/i)
    expect(wrapper.text()).toContain("There's something waiting for you")
    expect(wrapper.get('.invitation-tagline').classes()).toContain(
      'leading-[var(--line-height-handwritten-tight)]',
    )
    expect(wrapper.find('[data-scene="invitation"]').exists()).toBe(true)
    expect(wrapper.findAll('img[data-figma-node]').length).toBe(21)
    expect(wrapper.find('[data-role="invitation-headline"]').classes()).toContain(
      'invitation-title',
    )
    expect(wrapper.text()).not.toContain('Shara')
    expect(wrapper.text()).not.toContain('A celebration')
    expect(wrapper.find('[data-effect="falling-petals"]').exists()).toBe(true)
    expect(wrapper.find('[data-role="travel-polaroid"] img[alt]').exists()).toBe(true)
    expect(wrapper.get('.invitation-polaroid-photo').attributes('src')).toContain(
      '/backgrounds/invitation/hero-landscape.webp',
    )
    expect(wrapper.find('[data-interaction="brother-letter"]').exists()).toBe(true)
    expect(wrapper.find('img[src*="invitation-envelope"]').exists()).toBe(false)
    expect(wrapper.get('.invitation-polaroid-caption').text()).toBe('Day with Noah')
    expect(wrapper.find('.invitation-scene-layer--sway-envelope').exists()).toBe(true)
    expect(wrapper.find('[data-action="hold-enter-alternative"]').exists()).toBe(false)
  })

  it('preserves scene art DOM contracts, motion classes, and corrected Unicode copy', () => {
    const wrapper = mount(InvitationPage)
    const background = wrapper.findAll('.invitation-scene-art > img[data-figma-node]')
    const foreground = wrapper.findAll('.invitation-foreground > img[data-figma-node]')

    expect(background.length + foreground.length).toBe(INVITATION_LAYERS.length)
    expect(background.map((element) => element.attributes('data-figma-node'))).toEqual(
      INVITATION_LAYERS.filter((layer) => layer.plane === 'background').map(
        (layer) => layer.figmaNodeId,
      ),
    )
    expect(foreground.map((element) => element.attributes('data-figma-node'))).toEqual(
      INVITATION_LAYERS.filter((layer) => layer.plane === 'foreground').map(
        (layer) => layer.figmaNodeId,
      ),
    )
    expect(wrapper.findAll('img[data-figma-node]')).toHaveLength(21)
    expect(wrapper.get('img[data-figma-node="184:57"]').attributes('fetchpriority')).toBe('high')
    expect(background.every((layer) => layer.attributes('loading') !== undefined)).toBe(true)
    expect(foreground.every((layer) => layer.attributes('loading') === undefined)).toBe(true)
    expect(
      [...background, ...foreground].every((layer) => layer.attributes('aria-hidden') === 'true'),
    ).toBe(true)

    const html = wrapper.html()
    expect(html).toContain('\u2726')
    expect(html).toContain('\u2727')
    expect(html).toContain('\u2661')
    expect(html).not.toContain('\u00e2\u0153\u00a6')
    wrapper.unmount()
  })

  it('keeps hero and photo content configurable without owning route navigation', async () => {
    push.mockClear()
    const hero = mount(InvitationHeroCard, {
      props: {
        name: 'MIRA',
        age: 31,
        taglineLines: ['An invitation ', 'just for you ♡'],
        holdLabel: 'Open the experience',
        parchmentSrc: INVITATION_ASSETS.parchment.src,
        cardFlowerSrc: INVITATION_ASSETS.cardFlower.src,
        crownSrc: INVITATION_ASSETS.crown.src,
      },
    })
    expect(hero.get('[data-role="invitation-headline"]').text()).toMatch(/MIRA\s*31/)
    expect(hero.get('.invitation-tagline').text()).toContain('An invitation')
    expect(hero.get('.hold-label').text()).toBe('Open the experience')
    await hero.get('[data-action="hold-enter"]').trigger('keydown.enter')
    expect(hero.emitted('enter')).toHaveLength(1)
    expect(push).not.toHaveBeenCalled()
    expect(hero.findAll('img[data-figma-node]')).toHaveLength(3)
    hero.unmount()

    const photo = mount(InvitationPolaroid, {
      props: {
        src: '/other-photo.webp',
        alt: 'A different photograph',
        frameSrc: INVITATION_ASSETS.polaroid.src,
        caption: 'Another memory',
      },
    })
    expect(photo.get('.invitation-polaroid-photo').attributes('src')).toBe('/other-photo.webp')
    expect(photo.get('.invitation-polaroid-photo').attributes('alt')).toBe('A different photograph')
    expect(photo.get('.invitation-polaroid-caption').text()).toBe('Another memory')
    photo.unmount()
  })

  it('documents reusable assets with unique IDs, meaningful descriptions and public URLs', () => {
    const assets = Object.values(INVITATION_ASSETS)
    expect(assets).toHaveLength(17)
    expect(new Set(assets.map((asset) => asset.id)).size).toBe(17)
    expect(new Set(assets.map((asset) => asset.src)).size).toBe(17)
    expect(assets.every((asset) => asset.description.trim().length > 20)).toBe(true)
    expect(assets.every((asset) => asset.src.startsWith('/') && asset.src.endsWith('.webp'))).toBe(
      true,
    )

    expect(INVITATION_ASSETS.landscape).toMatchObject({
      id: 'painted-landscape-background',
      src: '/backgrounds/invitation/hero-landscape.webp',
    })
    expect(INVITATION_ASSETS.crown.src).toBe('/icons/invitation-crown.webp')
    expect(INVITATION_ASSETS.polaroid.src).toBe('/frames/polaroid/invitation-polaroid.webp')
    expect(
      INVITATION_LAYERS.every((layer) => assets.some((asset) => asset.src === layer.src)),
    ).toBe(true)
  })

  it('keeps every layer readable, stable, and independent from Figma node lookup', () => {
    expect(INVITATION_LAYERS).toHaveLength(17)
    expect(new Set(INVITATION_LAYERS.map((layer) => layer.id)).size).toBe(17)
    expect(new Set(INVITATION_LAYERS.map((layer) => layer.figmaNodeId)).size).toBe(17)
    expect(INVITATION_LAYERS.every((layer) => layer.description.length > 15)).toBe(true)
    expect(
      INVITATION_LAYERS.every((layer) => layer.frame.width > 0 && layer.frame.height > 0),
    ).toBe(true)
    const landscape = INVITATION_LAYERS.find((layer) => layer.id === 'hero-landscape')
    expect(landscape?.figmaNodeId).toBe('184:57')
    expect(landscape?.fetchPriority).toBe('high')
    expect(landscape?.responsiveClass).toContain('max-[600px]:object-[60%_center]')
    expect(INVITATION_LAYERS.find((layer) => layer.id === 'sakura-top-left')?.motion).toBe(
      'sway-left',
    )
  })
  it('allows the page to supply custom letter markup via named slots', () => {
    const letter = {
      openAriaLabel: 'Open a personal note',
      teaserLines: ['Default teaser'],
      title: 'Custom letter',
      note: 'Placeholder note',
      greeting: 'Hello,',
      paragraphs: ['Default paragraph'],
      signatureLines: ['From a friend'],
    }
    const wrapper = mount(BrotherLetter, {
      props: { letter },
      slots: {
        teaser: '<strong>Slot teaser</strong>',
        body: '<p>Custom body markup</p>',
      },
    })
    expect(wrapper.get('.brother-envelope__text').text()).toContain('Slot teaser')
    expect(wrapper.get('.brother-dialog__paper').text()).toContain('Custom body markup')
    expect(wrapper.text()).not.toContain('Default paragraph')
    wrapper.unmount()
  })

  it('keeps the visual artwork inaccessible to screen readers and preserves entry', async () => {
    const wrapper = mount(InvitationPage)
    expect(wrapper.findAll('img[data-figma-node][aria-hidden="true"]').length).toBe(21)
    push.mockClear()
    await wrapper.get('[data-action="hold-enter"]').trigger('keydown.enter')
    expect(push).toHaveBeenCalledWith('/entry')
  })
})
