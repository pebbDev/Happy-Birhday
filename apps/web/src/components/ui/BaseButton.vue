<script setup lang="ts">
withDefaults(defineProps<{ disabled?: boolean; type?: 'button' | 'submit' | 'reset' }>(), {
  disabled: false,
  type: 'button',
})
</script>

<template>
  <button class="base-button" :type="type" :disabled="disabled">
    <slot />
  </button>
</template>

<style scoped>
.base-button {
  min-height: 3rem;
  padding: .8rem 1.4rem;
  border: none;
  border-radius: 999px;
  color: #2a1630;
  font-weight: 750;
  background: linear-gradient(120deg, #f9beda, #ffe3c6);
  box-shadow: 0 8px 30px rgba(228, 136, 180, .18);
}
.base-button:hover:not(:disabled) { filter: brightness(1.08); }
</style>