<script setup lang="ts">
import UiEyebrow from '@/components/ui/UiEyebrow.vue'
import UiHint from '@/components/ui/UiHint.vue'
import UiLink from '@/components/ui/UiLink.vue'
import UiPageShell from '@/components/ui/UiPageShell.vue'
import UiPanel from '@/components/ui/UiPanel.vue'

defineProps<{ title: string; explanation: string }>()
</script>

<template>
  <UiPageShell>
    <UiPanel>
      <UiEyebrow>Frontend boilerplate</UiEyebrow>
      <h1>{{ title }}</h1>
      <p>{{ explanation }}</p>
      <slot />
      <UiHint>Ini hanya shell UI. Data dan akses privat belum dihubungkan ke Fastify.</UiHint>
      <UiLink to="/entry">Kembali ke akses</UiLink>
    </UiPanel>
  </UiPageShell>
</template>
