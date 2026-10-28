<script setup lang="ts">
import { onUnmounted, ref } from 'vue'
import { motion, useReducedMotion } from 'motion-v'
import type { BrotherLetterProps } from '../types/invitation.types'

const props = defineProps<BrotherLetterProps>()

const dialog = ref<HTMLDialogElement | null>(null)
const opened = ref(false)
const opening = ref(false)
let openTimer: ReturnType<typeof setTimeout> | undefined
const prefersReducedMotion = useReducedMotion()

function openLetter() {
  if (!dialog.value || dialog.value.open || opening.value) return
  opening.value = true
  const presentDialog = () => {
    if (!dialog.value) return
    dialog.value.showModal()
    opening.value = false
    opened.value = true
  }
  if (prefersReducedMotion.value) presentDialog()
  else openTimer = setTimeout(presentDialog, 280)
}
onUnmounted(() => {
  if (openTimer) clearTimeout(openTimer)
})
function closeLetter() {
  dialog.value?.close()
  opened.value = false
}
</script>

<template>
  <div class="brother-letter relative z-[3] w-full" data-interaction="brother-letter">
    <motion.button
      type="button"
      class="brother-envelope group relative block aspect-[1.5/1] w-full cursor-pointer border-0 bg-transparent p-0 drop-shadow-[var(--shadow-folded-card)] hover:drop-shadow-[var(--shadow-folded-card-hover)] focus-visible:rounded-xl focus-visible:outline-[3px] focus-visible:outline-offset-[6px] focus-visible:outline-[color:var(--color-message-focus)] motion-reduce:transition-none"
      :class="{ 'is-opening': opening }"
      :initial="false"
      :animate="{ rotate: opening ? -6 : -9, y: opening ? -7 : 0 }"
      :while-hover="prefersReducedMotion ? undefined : { rotate: -6, y: -8 }"
      :transition="{ duration: prefersReducedMotion ? 0 : 0.36, ease: 'easeInOut' }"
      :aria-label="props.letter.openAriaLabel"
      aria-haspopup="dialog"
      data-action="open-brother-letter"
      @click="openLetter"
    >
      <span
        class="brother-envelope__back absolute inset-0 block rounded-[var(--radius-envelope)] border border-[color:var(--color-folded-card-edge)] bg-[image:var(--gradient-folded-card-back)]"
        aria-hidden="true"
      ></span>
      <motion.span
        :initial="false"
        :animate="{ y: opening ? '-23%' : '0%' }"
        :transition="{ duration: prefersReducedMotion ? 0 : 0.28, ease: 'easeOut' }"
        class="brother-envelope__paper absolute inset-x-[10%] top-[12%] bottom-[16%] block rounded-[var(--radius-envelope)] bg-[color:var(--color-paper-sheet)] shadow-[var(--shadow-paper-sheet)]"
        aria-hidden="true"
      ></motion.span>
      <span
        class="brother-envelope__front absolute inset-0 block rounded-[var(--radius-envelope)] bg-[image:var(--gradient-folded-card-front)] [clip-path:polygon(0_18%,50%_70%,100%_18%,100%_100%,0_100%)]"
        aria-hidden="true"
      ></span>
      <motion.span
        :initial="false"
        :animate="{ rotateX: opening ? 172 : 0 }"
        :transition="{ duration: prefersReducedMotion ? 0 : 0.28, ease: 'easeOut' }"
        class="brother-envelope__flap absolute inset-0 block origin-top rounded-[var(--radius-envelope)] bg-[image:var(--gradient-folded-card-flap)] [backface-visibility:hidden] [clip-path:polygon(0_0,100%_0,50%_63%)] drop-shadow-[var(--shadow-paper-fold)]"
        aria-hidden="true"
      ></motion.span>
      <span
        class="brother-envelope__text pointer-events-none absolute left-[10%] top-[16%] w-[80%] rotate-[3deg] whitespace-nowrap text-center font-[family-name:var(--font-family-handwritten)] text-[length:var(--font-size-message-preview)] leading-[var(--line-height-message-preview)] text-[color:var(--color-message-preview)] [text-shadow:var(--shadow-message-preview)] max-[800px]:top-[18%] max-[800px]:text-[length:var(--font-size-message-preview-mobile)]"
        aria-hidden="true"
      >
        <slot name="teaser">
          <template v-for="(line, index) in props.letter.teaserLines" :key="index">
            {{ line }}<br v-if="index < props.letter.teaserLines.length - 1" />
          </template>
        </slot>
      </span>
      <span
        class="brother-envelope__seal absolute left-[43%] top-[60%] grid aspect-square w-[16%] place-items-center rounded-[var(--radius-seal)] bg-[image:var(--gradient-wax-seal)] text-[color:var(--color-wax-seal-foreground)] shadow-[var(--shadow-wax-seal)] [&_svg]:h-[60%] [&_svg]:w-[60%]"
        aria-hidden="true"
      >
        <svg viewBox="0 0 30 30" fill="none">
          <path
            d="m4 10 5 9h12l5-9-8 4-3-9-4 9-7-4Zm4 12h14"
            stroke="currentColor"
            stroke-width="2"
            stroke-linejoin="round"
            stroke-linecap="round"
          />
        </svg>
      </span>
      <span
        class="brother-envelope__hint absolute right-[1%] top-[63%] text-[length:var(--font-size-message-hint)] text-[color:var(--color-message-hint)]"
        aria-hidden="true"
        >✦</span
      >
    </motion.button>
    <dialog
      ref="dialog"
      class="brother-dialog fixed inset-0 m-auto box-border max-h-[min(82dvh,760px)] w-[min(90vw,600px)] max-w-[calc(100vw-24px)] overflow-x-hidden overflow-y-auto overscroll-contain rounded-xl border border-[color:var(--color-modal-paper-border)] bg-[color:var(--color-modal-paper-surface)] p-0 text-[color:var(--color-modal-paper-text-purple)] shadow-[var(--shadow-modal-paper)] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden backdrop:bg-[color:var(--color-message-backdrop)] backdrop:backdrop-blur-[var(--blur-dialog-backdrop)]"
      aria-labelledby="brother-dialog-title"
      @close="opened = false"
    >
      <motion.div
        class="brother-dialog__paper relative border-[10px] border-transparent [background:var(--gradient-paper-note)] p-[var(--spacing-message-padding)] font-[family-name:var(--font-family-display)] text-[length:var(--font-size-message-body)] leading-[var(--line-height-message-body)] text-[color:var(--color-paper-note-text-purple)]"
        :initial="false"
        :animate="opened && !prefersReducedMotion ? { y: [12, 0], opacity: [0, 1] } : {}"
        :transition="{ duration: 0.35, ease: 'easeOut' }"
      >
        <button
          type="button"
          class="brother-dialog__close absolute right-[10px] top-[6px] z-[3] h-[42px] w-[42px] cursor-pointer rounded-full border-0 bg-[color:var(--color-modal-close-surface)] font-sans text-[length:var(--font-size-control-close)] leading-none text-[color:var(--color-modal-close-text-purple)] focus-visible:outline-[3px] focus-visible:outline-[color:var(--color-message-focus)]"
          aria-label="Tutup surat"
          data-action="close-brother-letter"
          @click="closeLetter"
        >
          ×
        </button>
        <span
          aria-hidden="true"
          class="brother-dialog__flourish block text-center text-[length:var(--font-size-decorative-flourish)] text-[color:var(--color-decorative-flourish)]"
          >✧ ♡ ✧</span
        >
        <h2
          id="brother-dialog-title"
          class="m-0 mb-[var(--spacing-message-heading)] text-center text-[length:var(--font-size-message-heading)] font-medium"
        >
          {{ props.letter.title }}
        </h2>
        <p
          class="brother-dialog__eyebrow text-center font-sans text-xs leading-[var(--line-height-message-note)] text-[color:var(--color-message-note)]"
        >
          {{ props.letter.note }}
        </p>
        <slot name="body">
          <p
            class="my-[var(--spacing-message-paragraph)] text-[color:var(--color-paper-note-text-purple)]"
          >
            {{ props.letter.greeting }}
          </p>
          <p
            v-for="(paragraph, index) in props.letter.paragraphs"
            :key="index"
            class="my-[var(--spacing-message-paragraph)] text-[color:var(--color-paper-note-text-purple)]"
          >
            {{ paragraph }}
          </p>
        </slot>
        <p
          class="brother-dialog__signature my-[var(--spacing-message-paragraph)] text-[color:var(--color-paper-note-text-purple)] font-[family-name:var(--font-family-handwritten)] text-[length:var(--font-size-control-close)] leading-[var(--line-height-tight)]"
        >
          <template v-for="(line, index) in props.letter.signatureLines" :key="index">
            {{ line }}<br v-if="index < props.letter.signatureLines.length - 1" />
          </template>
        </p>
      </motion.div>
    </dialog>
  </div>
</template>
