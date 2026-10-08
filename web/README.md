# Apamuy · Panel web

Frontend web de Apamuy: **Admin** (equipo, rol `ADMIN`) y **Portal Socios** (negocios, rol `MERCHANT`). Alcance y decisiones en [docs/PANEL_WEB.md](../docs/PANEL_WEB.md).

## Stack

React 19 · Vite 8 · TypeScript 6 · Tailwind CSS 4 · shadcn/ui (Radix) · Zustand (sesión) · TanStack Query, Router y Table · React Hook Form + Zod · Axios · socket.io-client · Google Maps (`@vis.gl/react-google-maps`) · orval (cliente desde Swagger) · Vitest + Testing Library · Playwright · ESLint (Standard) + Prettier.

## Arranque

Requiere Node 22.12 o superior.

```bash
cd web
pnpm install
cp .env.example .env.local
pnpm run dev          # http://localhost:5173 (redirige /api y /ws al backend en :3000)
```

| Script               | Qué hace                                                    |
| -------------------- | ----------------------------------------------------------- |
| `pnpm run dev`       | Servidor de desarrollo                                      |
| `pnpm run build`     | Typecheck + build estático en `dist/`                       |
| `pnpm run typecheck` | Solo TypeScript                                             |
| `pnpm run lint`      | ESLint (Standard); `lint:fix` corrige lo automático         |
| `pnpm run format`    | Prettier (ordena las clases de Tailwind)                    |
| `pnpm test`          | Vitest                                                      |
| `pnpm run test:e2e`  | Playwright (antes: `pnpm exec playwright install chromium`) |

## Estructura

Ver `CLAUDE.md` (reglas) y `docs/PANEL_WEB.md` §9.

## Hecho (W0)

- Ingreso con celular + código SMS (`/login`), sesión que sobrevive a la recarga y renovación automática del token.
- Portales `/admin` (rol `ADMIN`) y `/partner` (rol `MERCHANT`) con guardas; los demás roles ven "Aún no eres socio".
- Armazón con sidebar (módulos planificados como "Pronto"), header y modo oscuro.
- Sesión JWT con Zustand; Axios con interceptores (Bearer, renovación única ante 401, `ApiError`).
- Tokens Terracota, fuentes, componentes base (`button`, `input`, `label`, `field`), hooks reutilizables, ESLint Standard con límites entre features, tests y CI.

## Pendiente

- `pnpm run api:generate` con el backend levantado (crea `src/api/generated/`) y pasar `features/auth/api` al cliente generado.
- Backend: refresh token en cookie httpOnly (hoy queda en `localStorage`, ver `docs/PANEL_WEB.md` §9).
- W1: Socios, Catálogo y Marketing sobre los endpoints `admin/*`.
