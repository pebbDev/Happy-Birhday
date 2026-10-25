import type { RouteRecordRaw } from 'vue-router'

// Page paths are design proposals. No protected content is bundled in this scaffold.
export const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'invitation',
    component: () => import('@/features/invitation/pages/InvitationPage.vue'),
  },
  {
    path: '/entry',
    name: 'protected-entry',
    component: () => import('@/features/protected-entry/pages/ProtectedEntryPage.vue'),
  },
  {
    path: '/world',
    name: 'birthday-world',
    component: () => import('@/features/birthday-world/pages/BirthdayWorldPage.vue'),
  },
  {
    path: '/photo-booth',
    name: 'photo-booth',
    component: () => import('@/features/photo-booth/pages/PhotoBoothPage.vue'),
  },
  {
    path: '/together/:inviteId?',
    name: 'async-together',
    component: () => import('@/features/async-together/pages/AsyncTogetherPage.vue'),
  },
  {
    path: '/memories',
    name: 'memory-wall',
    component: () => import('@/features/memories/pages/MemoryWallPage.vue'),
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/components/common/NotFoundPage.vue'),
  },
]