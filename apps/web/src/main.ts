import { createApp, createSSRApp } from 'vue'
import App from './app/App.vue'
import { router } from './app/router'
import './app/styles/main.css'

// The landing HTML is rendered at build time. Every non-SSG URL receives
// a separate neutral SPA shell (spa.html) via Vercel rewrite rules.
const mountElement = document.querySelector('#app')
if (!mountElement) throw new Error('Vue mount element #app is missing')

const isPrerendered = mountElement.getAttribute('data-render-mode') === 'ssg'
const app = isPrerendered ? createSSRApp(App) : createApp(App)
app.use(router)

// Allow the async route to resolve before the first hydration/mount.
void router.isReady().then(() => {
  app.mount(mountElement)
})
