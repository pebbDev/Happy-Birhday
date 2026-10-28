import assert from 'node:assert/strict'
import { readFile, readdir } from 'node:fs/promises'
import { resolve } from 'node:path'
import process from 'node:process'

const root = resolve(process.cwd(), 'dist')
const [ssg, spa] = await Promise.all([
  readFile(resolve(root, 'index.html'), 'utf8'),
  readFile(resolve(root, 'spa.html'), 'utf8'),
])
assert.match(ssg, /data-render-mode="ssg"/)
assert.match(ssg, /DIANA/)
assert.match(ssg, /Hold to enter/)
assert.match(ssg, /data-scene="invitation"/)
assert.equal((ssg.match(/data-figma-node=/g) ?? []).length, 21)
assert.doesNotMatch(ssg, /\/src\/assets\//)
assert.match(ssg, /\/backgrounds\/invitation\/hero-landscape\.webp/)
assert.doesNotMatch(ssg, /Shara 23|A little world/)
assert.doesNotMatch(
  ssg,
  /tencentcos|private-media|sixpence-none-the-richer-kiss-me|api\/mcp\/asset/,
)
assert.match(ssg, /\/assets\/index-[\w-]+\.css/)
assert.doesNotMatch(ssg, /Validasi PIN belum tersedia/)
assert.match(spa, /data-render-mode="csr"/)
assert.doesNotMatch(spa, /DIANA/)
assert.doesNotMatch(spa, /Hold to enter/)
const config = JSON.parse(await readFile('vercel.json', 'utf8'))
assert.equal(config.rewrites.at(-1)?.destination, '/spa.html')
// Private media must not be distributed, whether built locally or in CI.
const privatePattern = /photo-0661|travel-preview|sixpence-none-the-richer|__local_preview/i
const publicFiles = await readdir(root, { recursive: true })
assert.ok(
  !publicFiles.some((file) => privatePattern.test(file)),
  'Private preview file found in dist; build must only contain public-safe assets.',
)
const assetFiles = (await readdir(resolve(root, 'assets'))).filter((file) =>
  /\.(?:js|css)$/.test(file),
)
const deployedText = [
  ssg,
  spa,
  ...(await Promise.all(assetFiles.map((file) => readFile(resolve(root, 'assets', file), 'utf8')))),
].join('\n')
assert.ok(
  !privatePattern.test(deployedText),
  'Public HTML or JavaScript contains a private media identifier or local preview URL.',
)
process.stdout.write(
  'Rendering output verified: public SSG, neutral CSR fallback and static CSS links\n',
)
