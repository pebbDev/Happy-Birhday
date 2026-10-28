import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

const source = (path: string) => readFileSync(resolve(process.cwd(), 'src', path), 'utf8')
const categories = ['colors', 'depth', 'motion', 'spacing', 'typography'] as const
const tokenSource = Object.fromEntries(
  categories.map((category) => [category, source('app/styles/tokens/' + category + '.css')]),
) as Record<(typeof categories)[number], string>
const foundation = source('app/styles/tokens.css')
const visualFiles = [
  'features/invitation/pages/InvitationPage.vue',
  'features/invitation/components/InvitationHeroCard.vue',
  'features/invitation/components/InvitationPolaroid.vue',
  'features/invitation/components/BrotherLetter.vue',
  'features/invitation/components/HoldToEnter.vue',
  'features/invitation/components/InvitationArtLayers.vue',
  'components/effects/FallingPetals.vue',
  'lib/motion/presets.ts',
] as const
const consumers = visualFiles.map((file) => ({ file, code: source(file) }))

function rootDeclarations(css: string): string[] {
  const start = css.indexOf(':root {')
  expect(start).toBeGreaterThanOrEqual(0)
  const end = css.indexOf('\n}', start)
  expect(end).toBeGreaterThan(start)
  return [...css.slice(start, end).matchAll(/^\s*(--[\w-]+)\s*:/gm)].map((match) => match[1]!)
}

describe('Global visual token contract', () => {
  it('defines all shared tokens uniquely, without feature prefixes', () => {
    const names = categories.flatMap((category) => rootDeclarations(tokenSource[category]))
    expect(names.length).toBeGreaterThan(140)
    expect(new Set(names).size).toBe(names.length)
    for (const name of names) expect(name).not.toMatch(/-invitation(?:-|$)/)
    expect(existsSync(resolve(process.cwd(), 'src/app/styles/invitation.tokens.css'))).toBe(false)
    expect(foundation).not.toContain('invitation.tokens.css')
  })

  it('groups names by meaningful global CSS categories', () => {
    const prefixes = {
      colors: /^--(?:color|gradient)-/,
      depth: /^--(?:z|shadow|blur)-/,
      motion: /^--motion-/,
      spacing: /^--(?:space|spacing|radius|container|stroke-width)-/,
      typography: /^--(?:font|line-height|tracking)-/,
    }

    for (const category of categories) {
      for (const name of rootDeclarations(tokenSource[category])) {
        expect(name, category).toMatch(prefixes[category])
      }
    }
  })

  it('avoids duplicate raw colors in the palette', () => {
    const palette = [
      ...tokenSource.colors.matchAll(
        /^\s*--color-[\w-]+:\s*(#[\da-fA-F]+|rgba\([^)]*\)|rgb\([^)]*\));/gm,
      ),
    ].map((match) => match[1]!.toLowerCase().replace(/\s/g, ''))
    expect(palette.length).toBeGreaterThan(60)
    expect(new Set(palette).size).toBe(palette.length)
  })

  it('resolves references and does not leave renamed visual tokens unused', () => {
    const declared = new Set(
      categories.flatMap((category) => rootDeclarations(tokenSource[category])),
    )
    // Layout-local percentages are set per artwork layer, not global design tokens.
    const localLayerVariables = new Set(['--scene-x', '--scene-y', '--scene-w', '--scene-h'])
    const allSources =
      Object.values(tokenSource).join('\n') + '\n' + consumers.map(({ code }) => code).join('\n')

    for (const { file, code } of consumers) {
      const refs = [...code.matchAll(/var\((--[\w-]+)/g)].map((match) => match[1]!)
      for (const ref of refs) {
        expect(declared.has(ref) || localLayerVariables.has(ref), file + ': ' + ref).toBe(true)
      }
      expect(code, file).not.toMatch(/--[\w-]*invitation-[\w-]*/)
    }

    const decorativeTokens = Object.values(tokenSource)
      .flatMap((css) => [
        ...css.matchAll(/\/\* Shared decorative [^*]*tokens\. \*\/([\s\S]*?)(?=\n\s*\/\*|\n\})/g),
      ])
      .flatMap((match) =>
        [...match[1]!.matchAll(/^\s*(--[\w-]+)\s*:/gm)].map((definition) => definition[1]!),
      )

    expect(decorativeTokens.length).toBe(136)
    for (const name of decorativeTokens) {
      expect(allSources.includes('var(' + name + ')'), name).toBe(true)
    }
  })

  it('keeps literal colors, gradients and shadows out of visual components', () => {
    for (const { file, code } of consumers) {
      expect(code, file).not.toMatch(/#[\da-fA-F]{3,8}\b|\brgba?\(|\b(?:linear|radial)-gradient\(/)
    }
  })
})
