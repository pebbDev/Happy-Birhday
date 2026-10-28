<script setup lang="ts">
import { motion, useReducedMotion } from 'motion-v'

// Deterministic values keep public Invitation prerender and Vue hydration identical.
// Only small SVG-like decorative shapes are procedural; the large Figma artwork stays intact.
const petals = Array.from({ length: 19 }, (_, i) => ({
  id: i,
  left: 3 + ((i * 41 + 17) % 94),
  drift: -56 + ((i * 37) % 113),
  duration: 11 + (i % 6) * 1.6,
  delay: -((i * 19) % 18),
  scale: 0.56 + (i % 5) * 0.16,
  spin: 3.4 + (i % 4) * 0.8,
  blossom: i % 6 === 0,
}))
const prefersReducedMotion = useReducedMotion()
</script>

<template>
  <div
    v-if="!prefersReducedMotion"
    class="pointer-events-none absolute inset-0 z-[7] overflow-hidden"
    aria-hidden="true"
    data-effect="falling-petals"
  >
    <motion.span
      v-for="petal in petals"
      :key="petal.id"
      class="motion-gentle-fall absolute top-[-14%] h-[27px] w-[21px] opacity-90 max-[600px]:h-[21px] max-[600px]:w-[16px]"
      :class="{
        'h-[27px] w-[27px]': petal.blossom,
        'max-[600px]:hidden': petal.id >= 11,
      }"
      :initial="{ x: 0, y: '-10vh', rotate: 0, opacity: 0, scale: petal.scale }"
      :animate="{
        x: [0, petal.drift * 0.45, petal.drift],
        y: ['-10vh', '60vh', '126vh'],
        rotate: [0, 130, 285],
        opacity: [0, 0.91, 0.85, 0],
      }"
      :transition="{
        duration: petal.duration,
        delay: petal.delay,
        ease: 'linear',
        repeat: Infinity,
        times: [0, 0.08, 0.92, 1],
      }"
      :data-fall-duration="petal.duration"
      :data-fall-drift="petal.drift"
      :data-fall-scale="petal.scale"
      :style="{
        left: `${petal.left}%`,
      }"
    >
      <motion.span
        class="motion-gentle-tumble block h-full w-full"
        :initial="{ rotateX: 12, rotateY: 0, rotate: -24 }"
        :animate="{ rotateX: 172, rotateY: 135, rotate: 45 }"
        :transition="{
          duration: petal.spin,
          ease: 'easeInOut',
          repeat: Infinity,
          repeatType: 'reverse',
        }"
      >
        <svg
          v-if="petal.blossom"
          class="block h-full w-full drop-shadow-[var(--shadow-floral)]"
          viewBox="0 0 48 48"
          fill="none"
          aria-hidden="true"
        >
          <path
            d="M24 23C5 14 12 4 23 15C22 2 37 3 30 17C43 7 50 21 33 26C48 34 36 45 26 32C23 46 8 42 18 28C4 32 7 20 24 23Z"
            fill="var(--color-floral-blossom)"
            stroke="var(--color-floral-blossom-edge)"
            stroke-width="1.1"
          />
          <circle cx="24" cy="24" r="4" fill="var(--color-floral-blossom-center)" />
        </svg>
        <svg
          v-else
          class="block h-full w-full drop-shadow-[var(--shadow-floral)]"
          viewBox="0 0 40 52"
          fill="none"
          aria-hidden="true"
        >
          <path
            d="M20 49C-2 33 0 13 31 3C43 26 32 42 20 49Z"
            fill="var(--color-floral-leaf)"
            stroke="var(--color-floral-leaf-edge)"
            stroke-width="1.2"
          />
          <path d="M20 46Q21 24 31 6" stroke="var(--color-floral-vein)" stroke-width="1.2" />
        </svg>
      </motion.span>
    </motion.span>
  </div>
</template>
