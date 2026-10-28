<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    label: string
    inputTestId?: string
    min?: number
    max?: number
  }>(),
  { min: 0, max: 100 },
)

const model = defineModel<number>({ required: true })

function onInput(event: Event) {
  const target = event.target as HTMLInputElement | null
  if (target) model.value = Number(target.value)
}
</script>

<template>
  <label class="mt-5 flex flex-col gap-2 text-ui-text">
    <span
      >{{ props.label }}: <slot name="value">{{ model }}</slot></span
    >
    <input
      type="range"
      :data-testid="props.inputTestId"
      :min="props.min"
      :max="props.max"
      :value="model"
      class="w-full accent-ui-accent"
      @input="onInput"
    />
  </label>
</template>
