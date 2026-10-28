import { fileURLToPath, URL } from 'node:url'
import { readFile } from 'node:fs/promises'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vitest/config'

// Only during Vite development: expose one locally staged, private image to
// the same computer for visual QA. Production builds never include this plugin,
// media bytes or the local file path. No generic filesystem browsing is allowed.
function localPrivatePreview() {
  return {
    name: 'local-private-preview',
    apply: 'serve' as const,
    configureServer(server: import('vite').ViteDevServer) {
      server.middlewares.use(async (req, res, next) => {
        if (req.url?.split('?')[0] !== '/__local_preview/photo-0661.webp') {
          next()
          return
        }
        const ip = req.socket.remoteAddress ?? ''
        if (!['127.0.0.1', '::1', '::ffff:127.0.0.1'].includes(ip)) {
          res.statusCode = 403
          res.end()
          return
        }
        try {
          const image = await readFile(
            new URL('./.local-private/photos/photo-0661.webp', import.meta.url),
          )
          res.setHeader('Content-Type', 'image/webp')
          res.setHeader('Cache-Control', 'private, no-store')
          res.end(image)
        } catch {
          res.statusCode = 404
          res.end()
        }
      })
    },
  }
}

export default defineConfig({
  plugins: [vue(), tailwindcss(), localPrivatePreview()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  test: {
    environment: 'jsdom',
    include: ['src/**/__tests__/**/*.test.ts'],
    clearMocks: true,
  },
})
