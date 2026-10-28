<script setup lang="ts">
import { RouterView } from 'vue-router'
import { MotionConfig } from 'motion-v'
import { inject, shallowRef } from 'vue'
import { NAVIGATION_ERROR_KEY } from './router/navigation-error'
import BaseButton from '@/components/ui/BaseButton.vue'
import UiPanel from '@/components/ui/UiPanel.vue'

const hasNavigationError = inject(NAVIGATION_ERROR_KEY, shallowRef(false))

function reloadPage() {
  if (typeof window !== 'undefined') window.location.reload()
}
</script>

<template>
  <div
    v-if="hasNavigationError"
    role="alert"
    data-testid="navigation-error"
    class="fixed inset-x-4 top-4 z-[200] mx-auto max-w-xl"
  >
    <UiPanel tone="raised" padding="sm">
      <p class="font-semibold text-ui-text">Halaman gagal dimuat</p>
      <p class="mt-1 text-sm">Terjadi gangguan saat membuka halaman. Silakan coba muat ulang.</p>
      <BaseButton type="button" variant="secondary" size="sm" class="mt-3" @click="reloadPage">
        Muat ulang
      </BaseButton>
    </UiPanel>
  </div>
  <MotionConfig reduced-motion="user">
    <RouterView />
  </MotionConfig>
</template>
