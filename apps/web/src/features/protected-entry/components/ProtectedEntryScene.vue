<script setup lang="ts">
import UiEyebrow from '@/components/ui/UiEyebrow.vue'
import UiPageShell from '@/components/ui/UiPageShell.vue'
import UiPanel from '@/components/ui/UiPanel.vue'
import PinForm from './PinForm.vue'
</script>

<template>
  <UiPageShell>
    <UiPanel>
      <UiEyebrow>Private birthday world</UiEyebrow>
      <h1>Welcome in.</h1>
      <p>Masukkan PIN bersama untuk membuka pengalaman privat.</p>
      <PinForm />
    </UiPanel>
  </UiPageShell>
</template>
