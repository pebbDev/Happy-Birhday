<script setup lang="ts">
import { ref } from 'vue'
import BaseButton from '@/components/ui/BaseButton.vue'

const pin = ref('')
const notice = ref('')

function submit() {
  // Auth API endpoints/contracts are not implemented yet. Never fake success.
  notice.value = 'Validasi PIN belum tersedia: integrasi Fastify masih pending.'
}
</script>

<template>
  <form @submit.prevent="submit">
    <label class="form-field">
      <span>Shared PIN</span>
      <input
        v-model="pin"
        name="pin"
        type="password"
        inputmode="numeric"
        autocomplete="off"
        required
        placeholder="Masukkan PIN"
      />
    </label>
    <BaseButton type="submit">Buka Birthday World</BaseButton>
    <p v-if="notice" role="status" class="form-hint">{{ notice }}</p>
  </form>
</template>