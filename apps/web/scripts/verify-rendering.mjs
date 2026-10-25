import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import process from 'node:process'

const root = resolve(process.cwd(), 'dist')
const [ssg, spa] = await Promise.all([
  readFile(resolve(root, 'index.html'), 'utf8'),
  readFile(resolve(root, 'spa.html'), 'utf8'),
])
assert.match(ssg, /data-render-mode="ssg"/)
assert.match(ssg, /A little world/)
assert.match(ssg, /Tahan untuk masuk/)
assert.match(ssg, /InvitationPage-[\w-]+\.css/)
assert.match(ssg, /BaseButton-[\w-]+\.css/)
assert.doesNotMatch(ssg, /Validasi PIN belum tersedia/)
assert.match(spa, /data-render-mode="csr"/)
assert.doesNotMatch(spa, /A little world/)
assert.doesNotMatch(spa, /Tahan untuk masuk/)
const config = JSON.parse(await readFile('vercel.json', 'utf8'))
assert.equal(config.rewrites.at(-1)?.destination, '/spa.html')
process.stdout.write('Rendering output verified: public SSG, neutral CSR fallback and static CSS links\n')
