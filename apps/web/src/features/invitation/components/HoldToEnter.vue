<script setup lang="ts">
import { onUnmounted, ref } from 'vue'
import BaseButton from '@/components/ui/BaseButton.vue'

const emit = defineEmits<{ completed: [] }>()
const holding = ref(false)
let holdTimer: ReturnType<typeof setTimeout> | undefined

function cancelHold() {
  if (holdTimer) clearTimeout(holdTimer)
  holdTimer = undefined
  holding.value = false
}

function startHold(event: PointerEvent) {
  if (!event.isPrimary) return
  cancelHold()
  holding.value = true
  holdTimer = setTimeout(() => {
    cancelHold()
    emit('completed')
  }, 850)
}

function accessibleContinue() {
  cancelHold()
  emit('completed')
}

onUnmounted(cancelHold)
</script>

<template>
  <div class="hold-control">
    <BaseButton
      @pointerdown="startHold"
      @pointerup="cancelHold"
      @pointercancel="cancelHold"
      @pointerleave="cancelHold"
      @keydown.enter.prevent="accessibleContinue"
      @keydown.space.prevent="accessibleContinue"
    >
      {{ holding ? 'Tahan sebentar…' : 'Tahan untuk masuk' }}
    </BaseButton>
    <button type="button" class="accessible-link" @click="accessibleContinue">
      Lanjutkan tanpa menahan
    </button>
  </div>
</template>

<style scoped>
.hold-control { display: flex; flex-wrap: wrap; align-items: center; gap: 1rem; }
.accessible-link { border: 0; padding: .65rem; background: transparent; color: var(--text); text-decoration: underline; text-underline-offset: .3rem; }
</style>