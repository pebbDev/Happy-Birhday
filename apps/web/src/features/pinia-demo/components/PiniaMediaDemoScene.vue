<script setup lang="ts">
import MediaPlaybackControls from './MediaPlaybackControls.vue'
import MediaPlaybackSummary from './MediaPlaybackSummary.vue'
</script>

<template>
  <main class="min-h-svh bg-ui-page px-5 py-12 text-ui-text" data-scene="pinia-media-demo">
    <div class="mx-auto max-w-3xl">
      <h1 class="mb-2 text-3xl font-bold">Pinia skill — media preferences lab</h1>
      <p class="mb-6 text-ui-muted">
        Development-only example. No private videos or Tencent COS URLs are loaded.
      </p>
      <div class="grid gap-5 md:grid-cols-2">
        <MediaPlaybackControls />
        <MediaPlaybackSummary />
      </div>
    </div>
  </main>
</template>
