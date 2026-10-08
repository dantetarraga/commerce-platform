# web/ — Panel Apamuy (Admin y Portal Socios)

React 19 + Vite + TypeScript. Alcance y decisiones en [`docs/PANEL_WEB.md`](../docs/PANEL_WEB.md); la estructura está en §9.

## Estructura

- `app/`: `providers/` (QueryClient, router, interceptores), `router/` (todas las rutas y las guardas), `api/` (`http.ts`, `interceptors.ts`, `api-error.ts`, `generated/` de orval, que no se edita) y `config/` (`env.ts`, `navigation.ts`).
- `layouts/`: armazón de cada portal.
- `features/<dominio>/{api,components,hooks,layouts,model,pages,routes,schemas}` + `index.ts`. Una carpeta se crea cuando llega su primer archivo.
- `components/{ui,layout,shared}`, `hooks/` (hooks reutilizables), `lib/` (`cn`, `money`, `errors`, `datetime/`).

## Reglas

- Textos para el usuario en **español**; código, archivos y carpetas en inglés. Las URLs van en inglés (`/login`, `/partner`, `/admin/partners`). `/` es la landing pública (`features/landing`).
- Un feature **no importa de otro feature**, ni de `app/providers`, `app/router` o `layouts/`. Sí puede usar `@/app/api` y `@/app/config`. Lo compartido baja a `components`, `hooks` o `lib`. Desde fuera solo se importa `@/features/<x>`. ESLint lo hace cumplir.
- Rutas en código: los features exportan definiciones (`{ path, component, loader } as const`); solo `app/router/router.tsx` llama a `createRoute`.
- **Sesión con Zustand** (`features/auth/model/session.store.ts`): el access token vive en memoria y el refresh token se persiste. La lógica (`signIn`, `restoreSession`, `refreshAccessToken`) está en `session.ts`. Es el único estado global.
- **Datos del servidor con TanStack Query**. Las query keys y los hooks de cada feature van en su `api/`.
- **HTTP solo con `http` de `@/app/api`**. Los interceptores (Bearer, una renovación ante un 401, errores como `ApiError`) se conectan en `app/providers/http-setup.ts`.
- El backend es la fuente de verdad. Los permisos del cliente solo sirven para ocultar botones.
- Dinero en céntimos `{ amount, currency }` con `lib/money.ts`.
- **Fechas solo con `dateTime` de `@/lib/datetime`** (patrón adapter). La interfaz `DateTimeAdapter` es el contrato y `DateFnsAdapter` la implementación actual, en hora de Lima. Para cambiar de librería se escribe otra clase que implemente la interfaz, se agrega al test de contrato y se cambia la instancia en `lib/datetime/index.ts`.
- **Las librerías de infraestructura quedan encerradas en un solo lugar:** `date-fns` solo en `lib/datetime/` y `axios` solo en `app/api/`. ESLint lo hace cumplir.

## Componentes y hooks

- Un componente hace una sola cosa. Si un formulario tiene pasos, cada paso es su propio componente (ver `features/auth/components`).
- La lógica que se repite va en un custom hook: en `src/hooks/` si es genérica (`use-countdown`, `use-disclosure`) o en `features/<x>/hooks/` si es del dominio (`use-sign-out`).
- Las props de eventos se llaman `onX` y los handlers `handleX` (regla de Standard).
- Los componentes base van en `components/ui`, al estilo shadcn: `Button`, `Input`, `Label` y `Field`. Para agregar uno nuevo: `pnpm dlx shadcn@latest add <componente>` y adaptarlo a los tokens.

## Tailwind (v4)

- Solo se usan los tokens de `index.css`: `bg-primary`, `text-muted-foreground`, `bg-primary-soft` y `bg-success`. Nada de hex ni de colores de la paleta por defecto (`bg-orange-600`).
- El tema se define en CSS (`@theme`) y las utilidades propias con `@utility` (`corner-exit-l|m|s`). No hay `tailwind.config.js`.
- Sintaxis de v4: opacidad con barra (`bg-foreground/40`), `!` al final (`text-primary!`) y variables con `bg-(--var)`.
- Las variantes de un componente se definen con `cva` y las clases se combinan con `cn()`. `@apply` solo se usa en la capa base.
- Tema claro por defecto, sin seguir al sistema. El usuario lo cambia con `ThemeToggle` (landing, login y header) y se guarda en `localStorage`. El script de `index.html` lo aplica antes del primer pintado. Sobre fotos se usan `ink`, `ink-foreground` e `ink-accent`, que no cambian con el tema.
- Mobile first: los estilos base son para móvil y los breakpoints suben (`md:`, `lg:`). Para tamaños cuadrados se usa `size-*`.
- Los valores arbitrarios (`[…]`) son la excepción. Si un valor se repite, se convierte en token.
- El orden de las clases lo resuelve Prettier con `prettier-plugin-tailwindcss`.

## Estilo de código

ESLint con **Standard** (`neostandard`, que agrega TypeScript, react-hooks y react-refresh). El formato lo hace Prettier: sin `;`, comillas simples y también en JSX. Comentarios solo cuando explican un porqué que no se ve en el código.

## Comandos

Con **pnpm** (`packageManager` en `package.json`): `pnpm run dev` · `pnpm run build` · `pnpm run typecheck` · `pnpm run lint` (`lint:fix`) · `pnpm run format` · `pnpm test` · `pnpm run test:e2e` · `pnpm run api:generate` (con el backend levantado).
