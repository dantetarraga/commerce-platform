import neostandard, { resolveIgnoresFromGitignore } from 'neostandard'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import globals from 'globals'

const layerMessage =
  'Un feature no importa de otros features, de app/ ni de layouts/. Lo compartido va en components, hooks, lib o config.'

const restrictedLayers = (message) => [
  'error',
  {
    patterns: [
      {
        group: ['@/features/*', '@/app/*', '@/layouts/*'],
        message,
      },
    ],
  },
]

export default [
  ...neostandard({
    ts: true,
    noStyle: true,
    ignores: [...resolveIgnoresFromGitignore(), 'src/api/generated/**'],
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
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['@/features/*/**'],
              message:
                'Importa el feature por su index.ts (@/features/<x>), no sus archivos internos.',
            },
          ],
        },
      ],
    },
  },
  {
    files: ['src/features/**/*.{ts,tsx}'],
    rules: { 'no-restricted-imports': restrictedLayers(layerMessage) },
  },
  {
    files: ['src/{components,hooks,lib,config,api,realtime}/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': restrictedLayers(
        'Las capas compartidas no dependen de features, app/ ni layouts/.',
      ),
    },
  },
  {
    files: ['src/components/ui/**/*.tsx'],
    rules: { 'react-refresh/only-export-components': 'off' },
  },
]
