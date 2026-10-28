import { createApp, createSSRApp, shallowRef } from 'vue'
import {
  NAVIGATION_ERROR_KEY,
  registerNavigationErrorHandling,
} from './app/router/navigation-error'
import { mountWhenRouterReady } from './app/router/mount-when-ready'
import { createPinia } from 'pinia'
import App from './app/App.vue'
import { router } from './app/router'
import './app/styles/main.css'

// The landing HTML is rendered at build time. Every non-SSG URL receives
// a separate neutral SPA shell (spa.html) via Vercel rewrite rules.
const mountElement = document.querySelector('#app')
if (!mountElement) throw new Error('Vue mount element #app is missing')

const isPrerendered = mountElement.getAttribute('data-render-mode') === 'ssg'
const app = isPrerendered ? createSSRApp(App) : createApp(App)
// Register handlers before the router plugin starts initial navigation.
// Pinia remains first so guards/components can safely access stores.
app.use(createPinia())
const navigationError = shallowRef(false)
app.provide(NAVIGATION_ERROR_KEY, navigationError)
registerNavigationErrorHandling(router, navigationError, (error) => {
  console.error('[Vue Router] Navigation failed:', error)
})
app.use(router)

// Navigation can fail before hydration if a lazy route cannot be imported.
// Display a recoverable error instead of leaving the application blank.
void mountWhenRouterReady(
  router,
  () => app.mount(mountElement),
  (error) => {
    navigationError.value = true
    console.error('[Vue Router] Initial navigation failed:', error)
  },
).catch((error: unknown) => {
  console.error('[Vue] Application mount failed:', error)
  mountElement.textContent = 'Halaman gagal dimuat. Silakan muat ulang.'
})
