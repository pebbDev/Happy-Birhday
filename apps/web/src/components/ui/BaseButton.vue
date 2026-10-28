<script setup lang="ts">
type ButtonVariant = 'primary' | 'secondary' | 'ghost'
type ButtonSize = 'sm' | 'md' | 'lg'

const props = withDefaults(
  defineProps<{
    disabled?: boolean
    type?: 'button' | 'submit' | 'reset'
    variant?: ButtonVariant
    size?: ButtonSize
  }>(),
  {
    disabled: false,
    type: 'button',
    variant: 'primary',
    size: 'md',
  },
)

// Literal classes are intentional: Tailwind v4 can statically discover each variant.
const baseClass =
  'base-button inline-flex items-center justify-center gap-2 rounded-[var(--radius-full)] font-[750] transition-[filter,background-color,color,border-color,box-shadow] duration-[var(--motion-duration-fast)] ease-[var(--motion-ease-standard)] motion-reduce:transition-none'

const variantClasses: Record<ButtonVariant, string> = {
  // Preserve the pre-existing pink/gold gradient for the existing PIN form.
  primary:
    'border-0 bg-[image:var(--gradient-action-primary)] text-ui-primary-foreground shadow-ui-primary hover:not-disabled:brightness-[1.08]',
  secondary:
    'border border-ui-border bg-ui-surface-raised text-ui-text hover:not-disabled:bg-ui-surface',
  ghost:
    'border border-transparent bg-transparent text-ui-accent hover:not-disabled:bg-ui-surface-raised',
}

const sizeClasses: Record<ButtonSize, string> = {
  sm: 'min-h-10 px-4 py-2 text-sm',
  md: 'min-h-12 px-[1.4rem] py-[.8rem]',
  lg: 'min-h-14 px-8 py-3 text-lg',
}
</script>

<template>
  <button
    :class="[baseClass, variantClasses[props.variant], sizeClasses[props.size]]"
    :type="props.type"
    :disabled="props.disabled"
  >
    <slot />
  </button>
</template>
