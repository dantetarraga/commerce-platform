import neostandard, { resolveIgnoresFromGitignore } from 'neostandard'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import globals from 'globals'

const rule = (group, message) => ({ group, message })

const featureInternals = rule(
  ['@/features/*/**'],
  'Importa el feature por su index.ts (@/features/<x>), no sus archivos internos.',
)
const dateLibrary = rule(
  ['date-fns', 'date-fns/*', '@date-fns/*'],
  'Usa dateTime de @/lib/datetime: la librería de fechas solo se usa dentro de su adapter.',
)
const httpLibrary = rule(['axios'], 'Usa http de @/app/api: axios solo se usa dentro de app/api.')
const upperLayers = (message) =>
  rule(['@/features/*', '@/app/providers/*', '@/app/router/*', '@/layouts/*'], message)

const restrict = (...patterns) => ['error', { patterns }]

export default [
  ...neostandard({
    ts: true,
    noStyle: true,
    ignores: [...resolveIgnoresFromGitignore(), 'src/app/api/generated/**'],
  }),
  reactHooks.configs.flat['recommended-latest'],
  reactRefresh.configs.vite,
  {
    files: ['src/**/*.{ts,tsx}'],
    languageOptions: { globals: globals.browser },
    rules: {
      'no-void': ['error', { allowAsStatement: true }],
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      'no-restricted-imports': restrict(featureInternals, dateLibrary, httpLibrary),
    },
  },
  {
    files: ['src/features/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': restrict(
        upperLayers(
          'Un feature no importa de otros features, de app/providers, app/router ni layouts/.',
        ),
        dateLibrary,
        httpLibrary,
      ),
    },
  },
  {
    files: ['src/{components,hooks,lib}/**/*.{ts,tsx}', 'src/app/{api,config}/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': restrict(
        upperLayers('Las capas compartidas no dependen de features, providers, router ni layouts.'),
        dateLibrary,
        httpLibrary,
      ),
    },
  },
  {
    files: ['src/app/api/**/*.ts'],
    rules: {
      'no-restricted-imports': restrict(
        upperLayers('app/api no depende de features, providers, router ni layouts.'),
        dateLibrary,
      ),
    },
  },
  {
    files: ['src/lib/datetime/**/*.ts'],
    rules: { 'no-restricted-imports': restrict(featureInternals, httpLibrary) },
  },
  {
    files: ['src/components/ui/**/*.tsx'],
    rules: { 'react-refresh/only-export-components': 'off' },
  },
]
