<script setup lang="ts">
import { storeToRefs } from 'pinia'
import UiPanel from '@/components/ui/UiPanel.vue'
import { useMediaPlaybackStore } from '../stores/useMediaPlaybackStore'

const preferences = useMediaPlaybackStore()
const { muted, effectiveVolume } = storeToRefs(preferences)
</script>

<template>
  <UiPanel as="section" tone="raised" padding="sm">
    <h2 class="mb-3 text-lg font-semibold">Another component — shared state</h2>
    <p data-testid="muted-status">{{ muted ? 'Muted' : 'Sound enabled' }}</p>
    <p data-testid="effective-volume">Effective volume: {{ effectiveVolume }}%</p>
    <p class="mt-3 text-sm text-ui-muted">
      This component doesn't receive props. It reads the same Pinia store reactively.
    </p>
  </UiPanel>
</template>
