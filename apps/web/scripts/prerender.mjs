import { readFile, readdir, writeFile } from 'node:fs/promises'
import process from 'node:process'
import { resolve } from 'node:path'
import { createServer } from 'vite'

const root = process.cwd()
const output = resolve(root, 'dist')
const indexPath = resolve(output, 'index.html')
const template = await readFile(indexPath, 'utf8')
const placeholder = '<div id="app"></div>'
if (!template.includes(placeholder)) {
  throw new Error('Vite index.html is missing the expected Vue mount point')
}

// A separate shell ensures a direct visit to a CSR route does not attempt
// to hydrate public Invitation HTML while the Vue Router resolves that route.
const csrShell = template.replace(placeholder, '<div id="app" data-render-mode="csr"></div>')
await writeFile(resolve(output, 'spa.html'), csrShell)

const server = await createServer({
  configFile: resolve(root, 'vite.config.ts'),
  root,
  server: { middlewareMode: true },
  appType: 'custom',
  logLevel: 'error',
})

try {
  const { prerenderInvitation } = await server.ssrLoadModule('/src/entry-server.ts')
  const invitation = await prerenderInvitation()
  if (!invitation.includes('A little world')) {
    throw new Error('Invitation prerender produced unexpected or empty HTML')
  }
  // Load the CSS extracted from the lazy Invitation + shared Button chunks
  // before JavaScript so the pre-rendered experience is not unstyled.
  const assets = await readdir(resolve(output, 'assets'))
  const publicCriticalCss = assets
    .filter(name => /^(?:InvitationPage|BaseButton)-[\w-]+\.css$/.test(name))
    .map(name => `<link rel="stylesheet" href="/assets/${name}">`)
    .join('\n')
  const prerendered = template
    .replace('</head>', `${publicCriticalCss}\n</head>`)
    .replace(placeholder, `<div id="app" data-render-mode="ssg">${invitation}</div>`)
  await writeFile(indexPath, prerendered)
  process.stdout.write('Prerendered public Invitation /; generated neutral CSR spa.html\n')
} finally {
  await server.close()
}
