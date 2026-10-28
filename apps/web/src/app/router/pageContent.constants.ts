/**
 * Static public placeholder copy, separate from the router and view components.
 * These are not authenticated feature implementations.
 */
export const PENDING_PAGE_COPY = {
  'birthday-world': {
    title: 'Birthday World',
    explanation:
      'Scene naratif akan tersedia setelah integrasi akses dan konten privat melalui Fastify.',
  },
  'photo-booth': {
    title: 'Just Me Photo Booth',
    explanation:
      'Camera capture, review, dan finalisasi belum diimplementasikan dalam boilerplate.',
  },
  'async-together': {
    title: 'Async Together',
    explanation:
      'Perjalanan inisiasi, respons, dan kelanjutan sesi menunggu kontrak dan API Fastify.',
  },
  'memory-wall': {
    title: 'Memory Wall',
    explanation: 'Memori yang dipublikasikan akan diambil hanya setelah Fastify mengizinkan akses.',
  },
} as const
