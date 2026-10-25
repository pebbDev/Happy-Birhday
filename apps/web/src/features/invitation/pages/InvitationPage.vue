<script setup lang="ts">
import { useRouter } from 'vue-router'
import HoldToEnter from '../components/HoldToEnter.vue'

const router = useRouter()
function enter() { void router.push('/entry') }
</script>

<template>
  <main class="page invitation">
    <p class="eyebrow">A special invitation</p>
    <h1>A little world,<br />made for a special day.</h1>
    <p>
      Ada sesuatu yang istimewa menantimu. Masuk ketika kamu siap.
    </p>
    <div class="action-row">
      <HoldToEnter @completed="enter" />
    </div>
    <div class="card-grid" aria-label="Gambaran pengalaman publik">
      <article class="preview-card">
        <p class="eyebrow">01</p>
        <h2>A celebration</h2>
        <p>Sebuah awal perjalanan yang hangat.</p>
      </article>
      <article class="preview-card">
        <p class="eyebrow">02</p>
        <h2>A memory</h2>
        <p>Ruang untuk mengenang dan menciptakan momen baru.</p>
      </article>
    </div>
  </main>
</template>