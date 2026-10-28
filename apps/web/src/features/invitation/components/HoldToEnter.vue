<script setup lang="ts">
import { onUnmounted, shallowRef } from 'vue'
import { motion, useReducedMotion } from 'motion-v'

import type { HoldToEnterEmits, HoldToEnterProps } from '../types/invitation.types'

const props = defineProps<HoldToEnterProps>()

const emit = defineEmits<HoldToEnterEmits>()
const HOLD_DURATION_MS = 850
const RING_CIRCUMFERENCE = 2 * Math.PI * 45

const holding = shallowRef(false)
const progress = shallowRef(0)
const prefersReducedMotion = useReducedMotion()

let holdTimer: ReturnType<typeof setTimeout> | undefined
let progressFrame: number | undefined
let holdStartedAt = 0

function stopProgressFrame() {
  if (progressFrame !== undefined) cancelAnimationFrame(progressFrame)
  progressFrame = undefined
}

function cancelHold() {
  if (holdTimer !== undefined) clearTimeout(holdTimer)
  holdTimer = undefined
  stopProgressFrame()
  holding.value = false
  progress.value = 0
}

function updateProgress(now: number) {
  if (!holding.value) return
  progress.value = Math.min(1, Math.max(0, (now - holdStartedAt) / HOLD_DURATION_MS))
  if (progress.value < 1) progressFrame = requestAnimationFrame(updateProgress)
}

function startHold(event: PointerEvent) {
  if (!event.isPrimary) return
  cancelHold()
  holding.value = true
  holdStartedAt = performance.now()
  progressFrame = requestAnimationFrame(updateProgress)
  holdTimer = setTimeout(() => {
    holdTimer = undefined
    stopProgressFrame()
    progress.value = 1
    holding.value = false
    emit('completed')
  }, HOLD_DURATION_MS)
}

function accessibleContinue() {
  cancelHold()
  emit('completed')
}

onUnmounted(cancelHold)
</script>

<template>
  <div
    class="hold-control flex flex-col items-center gap-[var(--spacing-press-control-gap)] text-[color:var(--color-press-control-text-purple)]"
  >
    <motion.button
      type="button"
      class="hold-button group relative grid h-[clamp(70px,5.7vw,98px)] w-[clamp(70px,5.7vw,98px)] touch-none cursor-pointer place-items-center rounded-full border-2 border-[color:var(--color-press-control-border)] bg-[image:var(--gradient-press-control)] p-0 text-[color:var(--color-press-control-arrow)] shadow-[var(--shadow-press-control)] focus-visible:outline-[3px] focus-visible:outline-offset-[9px] focus-visible:outline-[color:var(--color-press-control-focus)] max-[800px]:h-[clamp(70px,19vw,94px)] max-[800px]:w-[clamp(70px,19vw,94px)] motion-reduce:transition-none"
      :class="{ 'is-holding': holding }"
      :initial="false"
      :animate="{ scale: holding ? 0.98 : 1 }"
      :while-hover="prefersReducedMotion ? undefined : { scale: 1.05 }"
      :transition="{ duration: prefersReducedMotion ? 0 : 0.2, ease: 'easeInOut' }"
      data-action="hold-enter"
      :aria-label="`${props.label}. Press Enter or Space to continue.`"
      @pointerdown="startHold"
      @pointerup="cancelHold"
      @pointercancel="cancelHold"
      @pointerleave="cancelHold"
      @keydown.enter.prevent="accessibleContinue"
      @keydown.space.prevent="accessibleContinue"
    >
      <svg
        class="hold-progress pointer-events-none absolute inset-[-8px] h-[calc(100%+16px)] w-[calc(100%+16px)] -rotate-90 overflow-visible [&_circle]:fill-none [&_circle]:[stroke-width:var(--stroke-width-progress)]"
        viewBox="0 0 100 100"
        aria-hidden="true"
        focusable="false"
      >
        <circle
          class="hold-progress-track"
          cx="50"
          cy="50"
          r="45"
          stroke="var(--color-press-control-track)"
          stroke-opacity="0.2"
        />
        <circle
          class="hold-progress-ring drop-shadow-[var(--shadow-press-control-ring)]"
          stroke="var(--color-press-control-progress)"
          stroke-linecap="round"
          :stroke-dasharray="RING_CIRCUMFERENCE"
          :stroke-dashoffset="RING_CIRCUMFERENCE * (1 - progress)"
          cx="50"
          cy="50"
          r="45"
        />
      </svg>
      <svg class="hold-arrow h-[36%] w-[36%]" viewBox="0 0 32 32" fill="none" aria-hidden="true">
        <path
          d="M5 16h22M18 7l9 9-9 9"
          stroke="currentColor"
          stroke-width="2.7"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </motion.button>
    <span
      class="hold-label mt-1 whitespace-nowrap font-[family-name:var(--font-family-display)] text-[length:var(--font-size-press-control-label)] leading-[var(--line-height-press-control-label)] text-[color:var(--color-press-control-text-purple)] max-[800px]:text-[length:var(--font-size-press-control-label-mobile)]"
      >{{ props.label }}</span
    >
  </div>
</template>
