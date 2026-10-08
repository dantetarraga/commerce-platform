import { defineConfig } from 'orval'

/**
 * Genera el cliente tipado desde el Swagger del backend.
 * Requiere el backend levantado en desarrollo: `npm run api:generate`.
 */
export default defineConfig({
  apamuy: {
    input: { target: process.env.OPENAPI_URL ?? 'http://localhost:3000/docs-json' },
    output: {
      target: 'src/api/generated/apamuy.ts',
      schemas: 'src/api/generated/model',
      mode: 'tags-split',
      client: 'react-query',
      httpClient: 'axios',
      clean: true,
      prettier: true,
      override: {
        mutator: { path: 'src/api/http.ts', name: 'apiMutator' },
        query: { useQuery: true, useSuspenseQuery: false },
      },
    },
  },
})
