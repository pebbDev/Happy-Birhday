<script setup lang="ts">
import FeaturePendingPage from '@/components/common/FeaturePendingPage.vue'
import UiHint from '@/components/ui/UiHint.vue'
import { PENDING_PAGE_COPY } from '@/app/router/pageContent.constants'

// Vue Router passes params as props; they remain reactive when the same
// component instance is reused for /together/first -> /together/second.
// When Fastify data retrieval exists, watch this prop with request cleanup
// rather than loading once from onMounted().
defineProps<{ inviteId: string | null }>()
</script>

<template>
  <FeaturePendingPage
    :title="PENDING_PAGE_COPY['async-together'].title"
    :explanation="PENDING_PAGE_COPY['async-together'].explanation"
  >
    <UiHint role="status" data-role="invite-route-context" :data-invite-id="inviteId ?? undefined">
      {{
        inviteId
          ? 'Tautan undangan telah dikenali. Data undangan baru tersedia setelah API Fastify terhubung.'
          : 'Tautan belum menyertakan ID undangan. Akses dan data masih menunggu integrasi Fastify.'
      }}
    </UiHint>
  </FeaturePendingPage>
</template>
