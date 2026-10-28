import js from '@eslint/js'
import tseslint from 'typescript-eslint'

export default [
  { ignores: ['dist/**', 'coverage/**', 'node_modules/**', 'src/generated/**'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.ts'],
    rules: {
      'no-undef': 'off', // TypeScript checks identifiers and types.
    },
  },
]
