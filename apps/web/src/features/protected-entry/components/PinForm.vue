<script setup lang="ts">
import { ref } from 'vue'
import BaseButton from '@/components/ui/BaseButton.vue'
import UiTextField from '@/components/ui/UiTextField.vue'
import UiHint from '@/components/ui/UiHint.vue'

const pin = ref('')
const notice = ref('')

function submit() {
  // Auth API endpoints/contracts are not implemented yet. Never fake success.
  notice.value = 'Validasi PIN belum tersedia: integrasi Fastify masih pending.'
}
</script>

<template>
  <form @submit.prevent="submit">
    <UiTextField
      v-model="pin"
      label="Shared PIN"
      name="pin"
      type="password"
      inputmode="numeric"
      autocomplete="off"
      required
      placeholder="Masukkan PIN"
    />
    <BaseButton type="submit">Buka Birthday World</BaseButton>
    <UiHint v-if="notice" role="status">{{ notice }}</UiHint>
  </form>
</template>
