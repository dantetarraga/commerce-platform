# web/ — Panel Apamuy (Admin y Portal Socios)

React 19 + Vite + TypeScript. Alcance y decisiones en [`docs/PANEL_WEB.md`](../docs/PANEL_WEB.md); la estructura está en §9.

## Estructura

- `app/`: `providers/` (QueryClient, router, interceptores), `router/` (todas las rutas y las guardas), `api/` (`http.ts`, `interceptors.ts`, `api-error.ts`, `query-keys.ts`, `lookups/` con las consultas que comparten varios features, `generated/` de orval, que no se edita) y `config/` (`env.ts`, `navigation.ts`).
- `layouts/`: armazón de cada portal.
- `features/<dominio>/` + `index.ts`. Una carpeta se crea cuando llega su primer archivo:
  - `actions/`: funciones `async` que llaman al backend con `http` (`getStore`, `createProduct`). Sin React ni caché.
  - `queries/`: `queryOptions` (clave de `queryKeys` + `queryFn` que llama a una action).
  - `mutations/`: `mutationOptions` (la action y qué invalida en `onSuccess`, con el `client` del contexto). El componente hace `useMutation(saveStoreMutation(id))`.
  - `stores/`: estado de cliente del módulo con Zustand (`<nombre>.store.ts`).
  - `components/`, `pages/`, `routes/`, `model/` (tipos y funciones puras), `schemas/` (Zod y payloads), `hooks/`, `layouts/`.
- `stores/`: estado de cliente global con Zustand (`theme.store.ts`).
- `components/{ui,layout,shared}`, `hooks/` (hooks reutilizables), `lib/` (`cn`, `money`, `errors`, `datetime/`).

## Reglas

- Textos para el usuario en **español**; código, archivos y carpetas en inglés. Las URLs van en inglés (`/login`, `/partner`, `/admin/partners`). `/` es la landing pública (`features/landing`).
- Un feature **no importa de otro feature**, ni de `app/providers`, `app/router` o `layouts/`. Sí puede usar `@/app/api` y `@/app/config`. Lo compartido baja a `components`, `hooks` o `lib`. Desde fuera solo se importa `@/features/<x>`. ESLint lo hace cumplir.
- Rutas en código: los features exportan definiciones (`{ path, component, loader } as const`); solo `app/router/router.tsx` llama a `createRoute`.
- **Zustand para estado de cliente** (los datos del servidor van en React Query, nunca en un store): store vanilla con `createStore`, acciones en `state.actions`, y hooks que seleccionan solo lo necesario (`useShallow` si devuelven un objeto). Lo que solo usa un componente sigue en `useState`. Las actualizaciones de Zustand son síncronas: lo que debe cambiar dentro de un `startTransition` va en estado de React.
- **Sesión** (`features/auth/stores/session.store.ts`): store vanilla (`createStore`) porque también lo leen las guardas y los interceptores; los componentes usan hooks con selector (`useCurrentUser`, `useSessionStatus`), nunca el store entero. Las acciones van en `state.actions`. El access token vive en memoria y solo se persiste el refresh token. La lógica (`signIn`, `restoreSession`, `refreshAccessToken`) está en `model/session.ts`; la renovación usa Web Locks y relee el token guardado, porque el backend cierra la sesión si un refresh token se reutiliza.
- **Rutas protegidas**: `beforeLoad` con `requireRole` (`app/router/guards.ts`). Si la sesión pasa a anónima (cerrar sesión, refresh rechazado u otra pestaña), `app/providers/session-sync.ts` invalida el router y las guardas redirigen.
- **Datos de página con Suspense**: el loader de la ruta llama a `queryClient.prefetchQuery` sin esperar, la página pinta su cabecera al instante y cada bloque con datos va en `<QueryBoundary fallback={<…Skeleton />}>` (`Suspense` + error boundary), con un componente hijo que lee con `useSuspenseQuery`. Los fallbacks son skeletons con la forma real (`components/ui/skeleton.tsx`). `useQuery` queda para consultas opcionales o con `enabled` dentro de formularios. Una búsqueda que cambia la clave se envuelve en `startTransition`.
- **Tiempo real**: `realtime` de `@/app/api` (una conexión Socket.IO a `/ws`, abierta mientras haya suscriptores) y el hook `useRealtimeEvent`. `socket.io-client` solo se importa en `app/api`.
- **Un mismo catálogo para dos portales**: `features/catalog` edita para el admin y para el dueño. `CatalogScopeContext` (`'admin'` o `'merchant'`) elige la base de los endpoints (`/admin` o `/merchant/catalog`) y las páginas del Portal Socios la fijan en `'merchant'`. El negocio elegido por el socio vive en `stores/partner-store.store.ts` y se lee con `usePartnerStore()`.
- **Gráficos**: `BarChart` (`components/shared/bar-chart.tsx`) para una serie, en el color `primary` (validado en claro y oscuro), con tooltip y tabla equivalente. Los datos agregados vienen calculados del backend.
- **Errores**: `describeError` (`lib/errors.ts`) decide título y texto. `ErrorState` para una página o sección que no cargó y `ErrorNotice` para formularios. Un 5xx nunca muestra el mensaje del backend, sino el estado y el `requestId` para soporte.
- **Datos del servidor con TanStack Query**. Todas las claves salen de `queryKeys` (`app/api/query-keys.ts`): una mutación de un feature puede invalidar datos de otro.
- **HTTP solo con `http` de `@/app/api`**. Los interceptores (Bearer, una renovación ante un 401, errores como `ApiError`) se conectan en `app/providers/http-setup.ts`.
- El backend es la fuente de verdad. Los permisos del cliente solo sirven para ocultar botones.
- Dinero en céntimos `{ amount, currency }` con `lib/money.ts`.
- **Fechas solo con `dateTime` de `@/lib/datetime`** (patrón adapter). La interfaz `DateTimeAdapter` es el contrato y `DateFnsAdapter` la implementación actual, en hora de Lima. Para cambiar de librería se escribe otra clase que implemente la interfaz, se agrega al test de contrato y se cambia la instancia en `lib/datetime/index.ts`.
- **Las librerías de infraestructura quedan encerradas en un solo lugar:** `date-fns` solo en `lib/datetime/` y `axios` solo en `app/api/`. ESLint lo hace cumplir.

## Componentes y hooks

- Un componente hace una sola cosa. Si un formulario tiene pasos, cada paso es su propio componente (ver `features/auth/components`).
- La lógica que se repite va en un custom hook: en `src/hooks/` si es genérica (`use-countdown`, `use-disclosure`) o en `features/<x>/hooks/` si es del dominio (`use-sign-out`).
- Las props de eventos se llaman `onX` y los handlers `handleX` (regla de Standard).
- El logo es `BrandLogo` ("APAMUY" en Bungee con sombra ocre) y `BrandMark` (la "A" en su baldosa), en `components/layout/brand-mark.tsx`. `font-brand` es solo para el logo.
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
