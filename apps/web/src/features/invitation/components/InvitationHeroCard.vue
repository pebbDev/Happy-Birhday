<script setup lang="ts">
import { CROWN_GLOW } from '@/lib/motion/presets'
import { motion, useReducedMotion } from 'motion-v'
import HoldToEnter from './HoldToEnter.vue'
import type { InvitationHeroCardEmits, InvitationHeroCardProps } from '../types/invitation.types'

defineProps<InvitationHeroCardProps>()
const emit = defineEmits<InvitationHeroCardEmits>()
const prefersReducedMotion = useReducedMotion()
</script>

<template>
  <section
    class="invitation-card-copy pointer-events-none absolute left-1/2 top-1/2 z-[3] aspect-[542/721] w-[clamp(420px,32.5vw,570px)] -translate-x-1/2 -translate-y-1/2 text-center max-[600px]:top-[29%] max-[600px]:w-[min(79vw,47svh,410px)] max-[600px]:translate-y-0 max-[360px]:top-[27%] max-[360px]:w-[min(82vw,46svh)] min-[601px]:max-[800px]:top-[38%] min-[601px]:max-[800px]:w-[min(58vw,490px)] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:w-[min(40vw,550px)]"
    aria-labelledby="invitation-title"
  >
    <img
      class="invitation-paper pointer-events-none absolute inset-0 h-full w-full object-fill"
      :src="parchmentSrc"
      data-figma-node="184:67"
      aria-hidden="true"
      alt=""
    />
    <img
      class="invitation-card-flowers pointer-events-none absolute right-[-6%] top-[-2%] z-[5] h-auto w-[48%] rotate-[-5deg]"
      :src="cardFlowerSrc"
      data-figma-node="184:73"
      aria-hidden="true"
      alt=""
    />
    <div
      class="invitation-crown pointer-events-none absolute left-1/2 top-[10%] z-[3] grid h-[9%] w-[19%] -translate-x-1/2 place-items-center max-[600px]:top-[9%] max-[600px]:w-[20%]"
      aria-hidden="true"
    >
      <span
        class="invitation-crown-light absolute inset-x-[-35%] inset-y-[-25%] bg-[image:var(--gradient-ornament-halo)] blur-[var(--blur-ornament-halo)]"
      ></span>
      <motion.img
        :initial="prefersReducedMotion ? false : CROWN_GLOW.initial"
        :animate="prefersReducedMotion ? undefined : CROWN_GLOW.animate"
        :transition="prefersReducedMotion ? undefined : CROWN_GLOW.transition"
        class="relative z-[2] h-full w-full object-contain"
        :src="crownSrc"
        data-figma-node="180:51"
        alt=""
        aria-hidden="true"
      />
      <motion.span
        :initial="prefersReducedMotion ? false : { opacity: 0.6 }"
        :animate="prefersReducedMotion ? undefined : { opacity: 1 }"
        :transition="
          prefersReducedMotion
            ? undefined
            : {
                duration: 2,
                repeat: Infinity,
                repeatType: 'reverse',
                ease: 'easeInOut',
                delay: 0,
              }
        "
        class="invitation-crown-star invitation-crown-star--left pointer-events-none absolute left-[-8%] top-[8%] z-[3] text-[length:var(--font-size-ornament-star)] text-[color:var(--color-ornament-star)] [text-shadow:var(--shadow-ornament-star)]"
        >✦</motion.span
      >
      <motion.span
        :initial="prefersReducedMotion ? false : { opacity: 0.6 }"
        :animate="prefersReducedMotion ? undefined : { opacity: 1 }"
        :transition="
          prefersReducedMotion
            ? undefined
            : {
                duration: 2,
                repeat: Infinity,
                repeatType: 'reverse',
                ease: 'easeInOut',
                delay: 0.7,
              }
        "
        class="invitation-crown-star invitation-crown-star--right pointer-events-none absolute right-[-10%] top-[39%] z-[3] text-[length:var(--font-size-ornament-star)] text-[color:var(--color-ornament-star)] [text-shadow:var(--shadow-ornament-star)]"
        >✧</motion.span
      >
    </div>
    <h1
      id="invitation-title"
      class="invitation-title absolute left-[3%] top-[22%] z-[2] m-0 w-[94%] font-[family-name:var(--font-family-display)] text-[length:var(--font-size-display-heading)] font-medium leading-[var(--line-height-display-heading)] tracking-[var(--tracking-display-heading)] text-[color:var(--color-text-heading-purple)] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:text-[length:var(--font-size-display-heading-landscape)] min-[601px]:max-[800px]:text-[length:var(--font-size-display-heading-tablet)] max-[600px]:top-[21%] max-[600px]:text-[length:var(--font-size-display-heading-mobile)] max-[360px]:text-[length:var(--font-size-display-heading-small)]"
      data-role="invitation-headline"
    >
      {{ name }}
      <span
        class="invitation-age mt-[3%] block text-[length:var(--font-size-display-figure)] font-normal leading-[var(--line-height-display-figure)] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:text-[length:var(--font-size-display-figure-landscape)] min-[601px]:max-[800px]:text-[length:var(--font-size-display-figure-tablet)] max-[600px]:text-[length:var(--font-size-display-figure-mobile)] max-[600px]:leading-[var(--line-height-display-heading)] max-[360px]:text-[length:var(--font-size-display-figure-small)]"
        >{{ age }}</span
      >
    </h1>
    <p
      class="invitation-tagline absolute left-[8%] top-[51%] z-[3] m-0 w-[84%] rotate-[-4deg] font-[family-name:var(--font-family-handwritten)] text-[length:var(--font-size-display-subheading)] leading-[var(--line-height-handwritten-tight)] text-[color:var(--color-text-purple)] min-[601px]:max-[800px]:text-[length:var(--font-size-display-subheading-tablet)] max-[600px]:left-[5%] max-[600px]:top-[48%] max-[600px]:w-[90%] max-[600px]:text-[length:var(--font-size-display-subheading-mobile)] max-[360px]:top-[47%] max-[360px]:text-[length:var(--font-size-display-subheading-small)]"
    >
      <template v-for="(line, index) in taglineLines" :key="index">
        {{ line }}<br v-if="index < taglineLines.length - 1" />
      </template>
    </p>
    <HoldToEnter
      class="invitation-cta pointer-events-auto absolute left-0 top-[69%] z-[4] w-full min-[601px]:max-[800px]:top-[70%] max-[600px]:top-[64%] max-[360px]:top-[61%]"
      :label="holdLabel"
      @completed="emit('enter')"
    />
  </section>
</template>
