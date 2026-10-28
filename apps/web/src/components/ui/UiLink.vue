<script setup lang="ts">
import { RouterLink, type RouteLocationRaw } from 'vue-router'

defineProps<{ to: RouteLocationRaw }>()
</script>

<template>
  <RouterLink :to="to" class="text-ui-accent underline-offset-[.2rem] hover:underline">
    <slot />
  </RouterLink>
</template>
