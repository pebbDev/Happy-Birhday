<script setup lang="ts">
type PanelTone = 'default' | 'raised'
type PanelPadding = 'sm' | 'md' | 'lg'

const props = withDefaults(
  defineProps<{ as?: 'div' | 'section'; tone?: PanelTone; padding?: PanelPadding }>(),
  { as: 'div', tone: 'default', padding: 'md' },
)

const toneClasses: Record<PanelTone, string> = {
  default: 'bg-ui-surface',
  raised: 'bg-ui-surface-raised shadow-ui-floating',
}

const paddingClasses: Record<PanelPadding, string> = {
  sm: 'p-4',
  md: 'p-[clamp(1.5rem,5vw,3rem)]',
  lg: 'p-8',
}
</script>

<template>
  <component
    :is="props.as"
    :class="[
      'rounded-ui-panel border border-ui-border',
      toneClasses[props.tone],
      paddingClasses[props.padding],
    ]"
  >
    <slot />
  </component>
</template>
