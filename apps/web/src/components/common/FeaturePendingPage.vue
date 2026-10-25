<script setup lang="ts">
import { RouterLink } from 'vue-router'

defineProps<{ title: string; explanation: string }>()
</script>

<template>
  <main class="page">
    <div class="panel">
      <p class="eyebrow">Frontend boilerplate</p>
      <h1>{{ title }}</h1>
      <p>{{ explanation }}</p>
      <p class="form-hint">Ini hanya shell UI. Data dan akses privat belum dihubungkan ke Fastify.</p>
      <RouterLink class="link" to="/entry">Kembali ke akses</RouterLink>
    </div>
  </main>
</template>