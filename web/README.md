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

- `pnpm run api:generate` con el backend levantado (crea `src/app/api/generated/`) y pasar los contratos manuales al cliente generado.
- Backend: refresh token en cookie httpOnly (hoy queda en `localStorage`, ver `docs/PANEL_WEB.md` §9).
- Completar W1: edición de variantes y opciones de productos, cupones y banners (Marketing).

## Primera entrega de W1: Socios y Catálogo

- `/admin/partners`: búsqueda exacta por celular, alta de negocio/repartidor, asignación de negocios, edición de vehículo y suspensión por rol con confirmación. El backend todavía no ofrece un listado general de socios.
- `/admin/catalog`: búsqueda y filtros de negocios, creación en borrador y gestión de categorías.
- `/admin/catalog/:storeId`: datos y dueño del negocio (búsqueda por celular), publicación, retiro, horarios con múltiples turnos y cruce de medianoche, secciones, alta/edición/retiro de productos, precio, stock y disponibilidad.
- Variantes y opciones existentes se muestran en consulta y se conservan al editar; su editor completo queda pendiente. Las imágenes se ingresan por URL https; falta subida de archivos en el backend.
- Datos con TanStack Query y rutas cargadas bajo demanda; validación en español y estados de carga, vacío, error y reintento. El servidor mantiene las validaciones y los permisos definitivos.
- Ajuste del backend: `POST admin/couriers` conserva `activeSince` al editar el vehículo si no se envía ese campo; no requiere migración.

Validación: 40 pruebas unitarias de web y 10 pruebas de navegador en Chromium con API simulada, además del build y lint. Las pruebas de navegador cubren guardas, alta, suspensión selectiva y bloqueada, publicación, edición sin perder opciones, horarios, reintento y móvil/modo oscuro. No equivalen a una prueba contra la base de datos real. El ajuste del backend tiene 2 pruebas de regresión.
