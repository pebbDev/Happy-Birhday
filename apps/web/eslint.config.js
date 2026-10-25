import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import vue from 'eslint-plugin-vue'

export default [
  { ignores: ['dist/**', 'coverage/**', 'node_modules/**', '*.tsbuildinfo'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...vue.configs['flat/essential'],
  {
    files: ['**/*.{ts,vue}'],
    rules: { 'no-undef': 'off' }, // TypeScript checks typed/global identifiers.
  },
  {
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: {
        parser: tseslint.parser,
        extraFileExtensions: ['.vue'],
      },
    },
  },
]