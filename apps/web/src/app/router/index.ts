import { createRouter, createWebHistory } from 'vue-router'
import { routes } from './routes'

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

// IMPORTANT: Router guards provide navigation UX, NOT authorization.
// Do not add fake client-only PIN/session checks; require Fastify integration.