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
  const serverHtml = await prerenderInvitation()
  // Vite's dev SSR emits /src/assets URLs; production files are fingerprinted.
  // Replace every rendered image source with its unique emitted build asset.
  const assets = await readdir(resolve(output, 'assets'))
  const invitation = serverHtml.replace(/src="(\/src\/assets\/[^"]+)"/g, (_, sourcePath) => {
    const base = sourcePath.split('/').at(-1)
    const extension = base.slice(base.lastIndexOf('.'))
    const stem = base.slice(0, -extension.length)
    const matching = assets.filter(
      (name) => name.startsWith(stem + '-') && name.endsWith(extension),
    )
    if (matching.length !== 1) {
      throw new Error('Public Invitation asset could not be resolved uniquely: ' + sourcePath)
    }
    return 'src="/assets/' + matching[0] + '"'
  })
  if (invitation.includes('/src/assets/')) {
    throw new Error('Unresolved source asset in prerendered Invitation')
  }
  if (!invitation.includes('DIANA') || !invitation.includes('data-scene="invitation"')) {
    throw new Error('Invitation prerender produced unexpected or empty HTML')
  }
  // Load the CSS extracted from the lazy Invitation chunk
  // before JavaScript so the pre-rendered experience is not unstyled.
  const publicCriticalCss = assets
    .filter((name) => /^InvitationPage-[\w-]+\.css$/.test(name))
    .map((name) => `<link rel="stylesheet" href="/assets/${name}">`)
    .join('\n')
  const prerendered = template
    .replace('</head>', `${publicCriticalCss}\n</head>`)
    .replace(placeholder, `<div id="app" data-render-mode="ssg">${invitation}</div>`)
  await writeFile(indexPath, prerendered)
  process.stdout.write('Prerendered public Invitation /; generated neutral CSR spa.html\n')
} finally {
  await server.close()
}
