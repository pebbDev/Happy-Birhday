<script setup lang="ts">
import { storeToRefs } from 'pinia'
import BaseButton from '@/components/ui/BaseButton.vue'
import UiPanel from '@/components/ui/UiPanel.vue'
import UiRangeField from '@/components/ui/UiRangeField.vue'
import { useMediaPlaybackStore } from '../stores/useMediaPlaybackStore'

const preferences = useMediaPlaybackStore()
const { muted, volume } = storeToRefs(preferences)
const { toggleMuted, setVolume, reset } = preferences
</script>

<template>
  <UiPanel as="section" tone="raised" padding="sm">
    <h2 class="mb-3 text-lg font-semibold">Playback controls</h2>
    <BaseButton
      type="button"
      variant="secondary"
      size="sm"
      data-testid="toggle-mute"
      @click="toggleMuted()"
    >
      {{ muted ? 'Unmute' : 'Mute' }}
    </BaseButton>
    <UiRangeField
      label="Volume"
      input-test-id="volume-input"
      :model-value="volume"
      @update:model-value="setVolume"
    >
      <template #value>
        <strong data-testid="volume-label">{{ volume }}</strong
        >%
      </template>
    </UiRangeField>
    <BaseButton
      type="button"
      variant="ghost"
      size="sm"
      data-testid="reset-media"
      class="mt-4"
      @click="reset()"
    >
      Reset preferences
    </BaseButton>
  </UiPanel>
</template>
