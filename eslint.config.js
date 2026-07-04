import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import { defineConfig, globalIgnores } from 'eslint/config'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{js,jsx}'],
    extends: [
      js.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      globals: globals.browser,
      parserOptions: { ecmaFeatures: { jsx: true } },
    },
    rules: {
      // Standard Vite React template rule: JSX component/icon imports are
      // capitalized and used by the JSX transform, not as plain identifiers.
      'no-unused-vars': ['error', { varsIgnorePattern: '^[A-Z_]', argsIgnorePattern: '^_', caughtErrors: 'none' }],
      // React-Compiler-era rules that flag this app's established (and working)
      // load-from-IndexedDB-on-mount pattern; revisit if the compiler is adopted.
      'react-hooks/set-state-in-effect': 'off',
      'react-hooks/immutability': 'off',
      'react-hooks/purity': 'off',
      'react-hooks/refs': 'off',
    },
  },
  {
    // Context files intentionally export a provider component plus its hook.
    files: ['src/components/Toast.jsx', 'src/store/SettingsContext.jsx'],
    rules: { 'react-refresh/only-export-components': 'off' },
  },
])
