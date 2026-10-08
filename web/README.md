# Apamuy · Panel web

Frontend web de Apamuy: **Admin** (equipo, rol `ADMIN`) y **Portal Socios** (negocios, rol `MERCHANT`). Alcance y decisiones en [docs/PANEL_WEB.md](../docs/PANEL_WEB.md).

## Stack

React 19 · Vite 8 · TypeScript 6 · Tailwind CSS 4 · shadcn/ui (Radix) · Zustand (sesión) · TanStack Query, Router y Table · React Hook Form + Zod · Axios · socket.io-client · Google Maps (`@vis.gl/react-google-maps`) · orval (cliente desde Swagger) · Vitest + Testing Library · Playwright · ESLint (Standard) + Prettier.

## Arranque

Requiere Node 22.12 o superior.

```bash
cd web
npm install
cp .env.example .env.local
npm run dev          # http://localhost:5173 (redirige /api y /ws al backend en :3000)
```

| Script              | Qué hace                                              |
| ------------------- | ----------------------------------------------------- |
| `npm run dev`       | Servidor de desarrollo                                |
| `npm run build`     | Typecheck + build estático en `dist/`                 |
| `npm run typecheck` | Solo TypeScript                                       |
| `npm run lint`      | ESLint (Standard); `lint:fix` corrige lo automático   |
| `npm run format`    | Prettier (ordena las clases de Tailwind)              |
| `npm test`          | Vitest                                                |
| `npm run test:e2e`  | Playwright (antes: `npx playwright install chromium`) |

## Estructura

Ver `CLAUDE.md` (reglas) y `docs/PANEL_WEB.md` §9.

## Hecho (W0)

- Ingreso con celular + código SMS (`/ingresar`), sesión que sobrevive a la recarga y renovación automática del token.
- Portales `/admin` (rol `ADMIN`) y `/socio` (rol `MERCHANT`) con guardas; los demás roles ven "Aún no eres socio".
- Armazón con sidebar (módulos planificados como "Pronto"), header y modo oscuro.
- Sesión JWT con Zustand; Axios con interceptores (Bearer, renovación única ante 401, `ApiError`).
- Tokens Terracota, fuentes, componentes base (`button`, `input`, `label`, `field`), hooks reutilizables, ESLint Standard con límites entre features, tests y CI.

## Pendiente

- `npm run api:generate` con el backend levantado (crea `src/api/generated/`) y pasar `features/auth/api` al cliente generado.
- Backend: refresh token en cookie httpOnly (hoy queda en `localStorage`, ver `docs/PANEL_WEB.md` §9).
- W1: Socios, Catálogo y Marketing sobre los endpoints `admin/*`.
