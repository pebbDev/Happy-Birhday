<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useMediaSource } from '@/services/media/useMediaSource'
import FallingPetals from '@/components/effects/FallingPetals.vue'
import InvitationArtLayers from '../components/InvitationArtLayers.vue'
import InvitationHeroCard from '../components/InvitationHeroCard.vue'
import InvitationPolaroid from '../components/InvitationPolaroid.vue'
import BrotherLetter from '../components/BrotherLetter.vue'
import { INVITATION_ASSETS, INVITATION_LAYERS } from '../constants/invitation.constants'

// Static scene composition lives in the Page, where its two layer planes are consumed.
const backgroundLayers = INVITATION_LAYERS.filter((layer) => layer.plane === 'background')
const foregroundLayers = INVITATION_LAYERS.filter((layer) => layer.plane === 'foreground')

// Static copy lives directly on template props.
// Private COS access APIs are pending; preserve the current SSR-safe media fallback.
const { src: photoSrc } = useMediaSource('invitation-polaroid')
const router = useRouter()

async function handleEnter() {
  try {
    await router.push('/entry')
  } catch {
    // Global navigation error handling reports lazy-route failures to the user.
  }
}
</script>

<template>
  <main
    class="invitation-stage relative isolate h-svh min-h-[680px] w-full overflow-hidden bg-[color:var(--color-canvas-rose)] text-[color:var(--color-text-purple)] max-[600px]:block max-[600px]:box-border max-[600px]:min-h-0 max-[600px]:max-h-svh max-[600px]:overflow-hidden min-[601px]:max-[800px]:h-auto min-[601px]:max-[800px]:min-h-[max(100svh,1120px)] min-[601px]:max-[800px]:overflow-x-clip"
    data-scene="invitation"
  >
    <div class="invitation-scene-art pointer-events-none absolute inset-0 z-0" aria-hidden="true">
      <InvitationArtLayers :layers="backgroundLayers" priority-loading />
    </div>

    <InvitationHeroCard
      name="DIANA"
      :age="28"
      :tagline-lines="[`There's something `, 'waiting for you ♡']"
      hold-label="Hold to enter"
      :parchment-src="INVITATION_ASSETS.parchment.src"
      :card-flower-src="INVITATION_ASSETS.cardFlower.src"
      :crown-src="INVITATION_ASSETS.crown.src"
      @enter="handleEnter"
    />

    <div
      class="invitation-accessories pointer-events-none absolute inset-0 z-[4] max-[600px]:block max-[600px]:m-0 max-[600px]:h-auto max-[600px]:w-auto"
    >
      <InvitationPolaroid
        :src="photoSrc"
        alt="Foto kenangan dalam bingkai Polaroid"
        :frame-src="INVITATION_ASSETS.polaroid.src"
        caption="Day with Noah"
      />

      <div
        class="invitation-envelope-position pointer-events-auto absolute bottom-[8%] right-[3%] w-[27%] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:bottom-[12%] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:right-[2%] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:w-[25%] min-[601px]:max-[800px]:bottom-[12%] min-[601px]:max-[800px]:right-[3%] min-[601px]:max-[800px]:w-[32%] max-[600px]:bottom-[9%] max-[600px]:right-[-3%] max-[600px]:w-[min(49vw,26svh,225px)] max-[360px]:bottom-[10%] max-[360px]:w-[min(50vw,25svh)]"
      >
        <BrotherLetter
          :letter="{
            openAriaLabel: 'Buka surat dari brother',
            teaserLines: ['A message', 'from your brother ♡'],
            title: 'A letter for Diana',
            note: 'Contoh pesan · menunggu pesan asli brother',
            greeting: 'Dear Diana,',
            paragraphs: [
              'Happy 28th birthday! Semoga setiap langkahmu ditemani keberanian, cinta, dan begitu banyak cerita yang indah.',
              'Teruslah mengejar hal-hal yang membuat hatimu berbinar. Semoga tahun ini membawa banyak alasan untuk tersenyum.',
            ],
            signatureLines: ['With love,', 'Your brother ♡'],
          }"
        />
      </div>
    </div>

    <div
      class="invitation-foreground pointer-events-none absolute inset-0 z-[6]"
      aria-hidden="true"
      data-layer="foreground"
    >
      <InvitationArtLayers :layers="foregroundLayers" />
    </div>
    <FallingPetals />
  </main>
</template>
