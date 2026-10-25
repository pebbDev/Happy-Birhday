import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { createMemoryHistory, createRouter } from 'vue-router'
import App from './app/App.vue'
import { routes } from './app/router/routes'

// SSG is deliberately restricted to public-safe Invitation.
// Never import/request protected backend data during this render.
export async function prerenderInvitation(): Promise<string> {
  const app = createSSRApp(App)
  const router = createRouter({ history: createMemoryHistory(), routes })
  app.use(router)
  await router.push('/')
  await router.isReady()
  return renderToString(app)
}
