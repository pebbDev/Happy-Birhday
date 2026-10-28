import type { RouteRecordRaw } from 'vue-router'
import { PENDING_PAGE_COPY } from './pageContent.constants'

// Page paths are design proposals. No protected content is bundled in this scaffold.
export const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'invitation',
    component: () => import('@/features/invitation/pages/InvitationPage.vue'),
  },
  {
    path: '/entry',
    component: () => import('@/features/protected-entry/pages/ProtectedEntryPage.vue'),
    children: [
      {
        path: '',
        name: 'protected-entry',
        component: () => import('@/features/protected-entry/components/ProtectedEntryScene.vue'),
      },
    ],
  },
  {
    path: '/world',
    component: () => import('@/features/birthday-world/pages/BirthdayWorldPage.vue'),
    children: [
      {
        path: '',
        name: 'birthday-world',
        component: () => import('@/components/common/FeaturePendingPage.vue'),
        props: PENDING_PAGE_COPY['birthday-world'],
      },
    ],
  },
  {
    path: '/photo-booth',
    component: () => import('@/features/photo-booth/pages/PhotoBoothPage.vue'),
    children: [
      {
        path: '',
        name: 'photo-booth',
        component: () => import('@/components/common/FeaturePendingPage.vue'),
        props: PENDING_PAGE_COPY['photo-booth'],
      },
    ],
  },
  {
    path: '/together/:inviteId?',
    component: () => import('@/features/async-together/pages/AsyncTogetherPage.vue'),
    children: [
      {
        path: '',
        name: 'async-together',
        component: () => import('@/features/async-together/components/AsyncTogetherScene.vue'),
        props: (route) => ({
          inviteId: typeof route.params.inviteId === 'string' ? route.params.inviteId : null,
        }),
      },
    ],
  },
  {
    path: '/memories',
    component: () => import('@/features/memories/pages/MemoryWallPage.vue'),
    children: [
      {
        path: '',
        name: 'memory-wall',
        component: () => import('@/components/common/FeaturePendingPage.vue'),
        props: PENDING_PAGE_COPY['memory-wall'],
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/components/common/NotFoundPage.vue'),
  },
]

// Isolated skill demonstration: no prototype UI or sample state shipped in production.
if (import.meta.env.DEV) {
  routes.push({
    path: '/__dev/pinia-media',
    component: () => import('@/features/pinia-demo/pages/PiniaMediaDemoPage.vue'),
    children: [
      {
        path: '',
        name: 'pinia-media-demo',
        component: () => import('@/features/pinia-demo/components/PiniaMediaDemoScene.vue'),
      },
    ],
  })
}
