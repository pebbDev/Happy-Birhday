<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    label: string
    name: string
    type?: 'text' | 'password' | 'email'
    inputmode?: 'numeric' | 'text' | 'decimal' | 'email'
    autocomplete?: string
    required?: boolean
    placeholder?: string
  }>(),
  { type: 'text', required: false },
)

const model = defineModel<string>({ required: true })
</script>

<template>
  <label class="my-[1.3rem] grid gap-[.55rem]">
    <span class="text-ui-text">{{ props.label }}</span>
    <input
      v-model="model"
      :name="props.name"
      :type="props.type"
      :inputmode="props.inputmode"
      :autocomplete="props.autocomplete"
      :required="props.required"
      :placeholder="props.placeholder"
      class="w-full rounded-[.65rem] border border-ui-border bg-ui-surface-raised px-4 py-[.85rem] text-ui-text"
    />
  </label>
</template>
