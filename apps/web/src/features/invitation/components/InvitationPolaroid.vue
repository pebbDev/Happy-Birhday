<script setup lang="ts">
import type { InvitationPolaroidProps } from '../types/invitation.types'

defineProps<InvitationPolaroidProps>()
</script>

<template>
  <figure
    class="invitation-polaroid pointer-events-none absolute bottom-[6%] left-[10%] m-0 aspect-[1122/1402] w-[23%] drop-shadow-[var(--shadow-photo-frame)] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:bottom-[8%] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:left-[3%] [@media(min-width:801px)_and_(max-aspect-ratio:14/10)]:w-[20%] min-[601px]:max-[800px]:bottom-[8%] min-[601px]:max-[800px]:left-[5%] min-[601px]:max-[800px]:w-[29%] max-[600px]:bottom-[5%] max-[600px]:left-[-4%] max-[600px]:w-[min(40vw,24svh,205px)] max-[600px]:drop-shadow-[var(--shadow-photo-frame-mobile)] max-[360px]:bottom-[4%] max-[360px]:w-[min(42vw,24svh)]"
    data-role="travel-polaroid"
  >
    <img
      class="invitation-polaroid-photo absolute inset-0 block h-full w-full object-cover object-[center_34%] [clip-path:polygon(9%_20%,81%_12%,92%_72%,19%_81%)]"
      :src="src"
      :alt="alt"
      loading="lazy"
    />
    <img
      class="invitation-polaroid-frame pointer-events-none absolute inset-0 block h-full w-full object-fill"
      :src="frameSrc"
      data-figma-node="196:170"
      alt=""
      aria-hidden="true"
    />
    <figcaption
      class="invitation-polaroid-caption pointer-events-none absolute left-[22%] top-[76%] z-[2] m-0 w-[64%] rotate-[-8deg] whitespace-nowrap text-center font-[family-name:var(--font-family-handwritten)] text-[length:var(--font-size-script-caption)] leading-[var(--line-height-tight)] text-[color:var(--color-photo-frame-script-caption)] max-[600px]:text-[length:var(--font-size-script-caption-mobile)]"
    >
      {{ caption }}
    </figcaption>
  </figure>
</template>
