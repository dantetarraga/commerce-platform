/// <reference types="vitest/config" />
import path from 'node:path'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: { '@': path.resolve(import.meta.dirname, './src') },
  },
  server: {
    port: 5173,
    // En desarrollo, la API y el WebSocket del backend se sirven desde el mismo
    // origen que el panel: así la cookie del refresh token funciona sin CORS.
    proxy: {
      '/api': 'http://localhost:3000',
      // Socket.IO: namespace /ws sobre la ruta /socket.io del servidor.
      '/socket.io': { target: 'http://localhost:3000', ws: true },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    exclude: ['e2e/**', 'node_modules/**'],
    setupFiles: ['./src/test/setup.ts'],
  },
})
