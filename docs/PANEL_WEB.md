# Apamuy — Panel web (Admin y Portal Socios)

Versión 0.2 · 2026-10-08 · Estado: **en implementación** · Complementa [ARQUITECTURA.md](ARQUITECTURA.md), [OPERACION.md](OPERACION.md) y [PENDIENTES.md](PENDIENTES.md).

Este documento define el frontend web de Apamuy: para qué sirve, quién lo usa, qué pantallas tiene, qué le falta al backend y con qué tecnología se puede construir. El código va en `web/`.

## 1. Por qué un panel web

El panel ya permite dar de alta socios y gestionar negocios, horarios, categorías, secciones y productos básicos. Los cupones, banners y la edición de variantes/opciones siguen en Swagger (`/docs`). Las siguientes entregas añadirán imágenes, pedidos en vivo y autogestión de negocios.

**Primera entrega de W1:** `/admin/partners`, `/admin/catalog` y `/admin/catalog/:storeId` conectados a la API existente, con validación, confirmaciones y estados de consulta. Las variantes y opciones se conservan al editar un producto y, por ahora, solo se consultan. El backend recibió un ajuste para conservar la antigüedad del repartidor cuando se edita su vehículo sin enviar `activeSince`; no requiere migración.

## 2. Referencia: Rappi y PedidosYa

Las dos plataformas separan la **operación en tiempo real** de la **autogestión**:

| | Recibir y operar pedidos | Autogestión (web) |
|---|---|---|
| **Rappi** | Rappi Aliados (app/tablet) | **Portal Partners**: menú, horarios y ajustes por tienda, KPIs y RappiScore, pagos y facturas descargables, promociones y RappiAds, soporte. La web no gestiona pedidos |
| **PedidosYa** | Sistema de recepción (POS/PC): aceptar, rechazar, imprimir, cerrar temporalmente, marcar agotados | **Partner Portal**: menú, horarios, logo y stock, reportes, descuentos y campañas. La app *PedidosYa Portal* lleva lo mismo al celular |

La razón: las comandas necesitan alarma e inmediatez (app); cargar un menú con fotos, ver reportes y bajar liquidaciones se hace mejor en una pantalla grande (web).

En Apamuy la operación ya existe: **Apamuy Socios** (modos Negocio y Repartidor). Falta la parte web.

Fuentes: [Rappi Portal Partners](https://merchants.rappi.com/es-pe/que-ofrecemos/plataforma-partners) · [Qué es Plataforma Partners](https://merchants.rappi.com/es-co/que-es-plataforma-partners-rappi) · [PedidosYa Portal](https://apps.apple.com/us/app/-/id6494987310) · [Registro en PedidosYa](https://www.c5n.com/sociedad/como-registro-mi-negocio-pedidos-ya-n108441)

## 3. Las piezas después del panel

| Pieza | Quién | Roles | Para qué |
|---|---|---|---|
| App Apamuy | Clientes | `CUSTOMER` | Pedir y seguir el pedido |
| App Apamuy Socios | Negocios y repartidores | `MERCHANT`, `COURIER` | Operar comandas y entregas (alarma, en vivo) |
| **Panel web · Admin** | Equipo Apamuy | `ADMIN` | Pedidos en vivo, socios, catálogo, marketing, ciudades, caja |
| **Panel web · Portal Socios** | Dueños de negocio | `MERCHANT` | Autogestión: menú, fotos, horarios, reportes, rendición |

- **Una sola web**, con el menú y las rutas según el rol (un `ADMIN` ve todo; un `MERCHANT` solo sus tiendas). Un mismo login, un mismo despliegue.
- Las **comandas se quedan en la app Socios** por la alarma. Una vista de comandas web para PC o tablet queda para cuando un negocio la pida.
- Los **repartidores no usan la web**.

## 4. Pantallas

### Admin (`ADMIN`)

| Módulo | Qué hace | Backend hoy |
|---|---|---|
| Pedidos en vivo | Tablero por ciudad: estado, tiempos, mapa de repartidores. Alertas de pedidos sin respuesta (3 min avisa, 8 min cancela, ver OPERACION §2). Cancelar, llamar al negocio o al cliente | ✅ `admin/orders/board` (columnas y alertas calculadas), `admin/orders` (historial por día), detalle y `cancel`. Sala `admin` en `/ws` (`admin.orders.changed`). Cancelación automática a los 8 min (`UnansweredOrdersJob`). Falta el mapa de repartidores |
| Socios | Buscar por celular, alta de negocio y repartidor, suspensión | ✅ `admin/users`, `admin/merchants`, `admin/couriers`, `suspend-partner` |
| Catálogo | Negocios (borrador → publicado), horarios, secciones, productos con variantes y opciones, categorías | ✅ `admin/stores`, `admin/products`, `admin/categories`. ❌ Subida de fotos |
| Marketing | Cupones y banners del inicio | ✅ `admin/coupons`, `admin/promotions`. Web: `/admin/marketing` |
| Ciudades | Cobertura (`coverageKm`), tarifas, `routeFactor`. Base para escalar fuera de Espinar | ✅ `admin/cities` (listar, crear inactiva, editar, pausar si no hay pedidos en curso), con ejemplos de tarifa calculados por el backend. Web: `/admin/cities` |
| Caja | Rendición diaria por repartidor y por negocio (efectivo, Yape, Plin) | ✅ `admin/cash?date&cityId`: por repartidor (cobrado vs. esperado, diferencia) y por negocio. Web: `/admin/cash` |

### Portal Socios (`MERCHANT`)

| Módulo | Qué hace | Backend hoy |
|---|---|---|
| Mi tienda | Datos, logo, portada, horarios | ✅ `merchant/catalog/stores/:id` (descripción, teléfono, logo, portada, preparación, pedido mínimo), horarios y pausa. Nombre, dirección y publicación los decide Apamuy. Web: `/partner/store` |
| Menú | Secciones, productos, precios, fotos, disponibilidad | ✅ `merchant/catalog/*` (secciones y productos) con los servicios del admin y control de dueño. Web: `/partner/menu`. ❌ Fotos (W2) |
| Reportes | Ventas por día y semana, pedidos entregados y cancelados | ✅ `merchant/reports?from&to` (hasta 92 días, por día y por hora, comparado con el periodo anterior). Web: `/partner/reports` |
| Rendición | Lo cobrado y lo que corresponde al negocio | 🟡 `merchant/settlement`: vendido y cobrado por día de entrega. `commission: null` hasta definir la comisión (OPERACION §4). Web: `/partner/settlement` |
| Después | Promociones propias, reseñas, solicitud de afiliación con documentos | ❌ |

## 5. Cambios necesarios en el backend

1. **Auth en el navegador.** Hoy el refresh token viaja en el body y la app lo guarda en secure storage. En la web va en **cookie httpOnly + Secure + SameSite**, con un endpoint de refresh que la lea, y el access token solo en memoria. Agregar el dominio del panel a la lista blanca de CORS. Definir si el admin entra con OTP por SMS (costo Twilio) u otro método.
2. **Pedidos para el admin:** `GET admin/orders` (filtros por ciudad, estado, fecha; cursor), detalle y acciones (cancelar con motivo).
3. **Imágenes:** storage (S3/R2) con URLs prefirmadas y CDN. Bloquea el catálogo real (ya pendiente en PENDIENTES).
4. **Catálogo del negocio:** endpoints `merchant/*` para editar su menú y horarios, reutilizando los servicios de `admin/catalog` con ownership por `store.ownerId`.
5. **Ciudades:** `admin/cities` para editar parámetros de reparto.
6. **Reportes:** agregados por rango de fechas.
7. **Liquidaciones:** primero definir la comisión y el pago a negocios (OPERACION §4); después modelarlo.

## 6. Tecnología

**Decidido (2026-10-08): React + Vite + TypeScript.** Se evaluó también Vue 3: sirve igual, pero React tiene más librerías de primera mano para mapas y formularios complejos, y más gente disponible. Proyecto creado en `web/` (ver `web/README.md`).

El panel es un back-office detrás de login: tablas densas, formularios largos (productos con variantes y opciones), subida de fotos, mapa y tiempo real. No necesita SEO.

| Opción | A favor | En contra |
|---|---|---|
| **React + Vite (SPA)** | Ecosistema más grande para back-office (tablas, formularios, mapas). Build estático: se sirve desde un CDN sin servidor. TypeScript igual que el backend | Hay que portar el diseño (tokens a CSS) |
| **Next.js** | Lo mismo que React, más SSR y rutas de servidor. Útil si además se quiere una landing pública de afiliación | Un servidor más que desplegar; el SSR no aporta detrás de login |
| **Angular** | Estructura con opinión (módulos, DI), parecida a NestJS | Más ceremonia; ecosistema de componentes más chico |
| **Flutter Web** | Reutiliza el design system y los modelos Dart de `mobile/`. Un solo lenguaje para todos los clientes | Bundle pesado y primera carga lenta; tablas, formularios y texto seleccionable rinden peor; menos librerías de back-office |

**Stack instalado:**

- **TypeScript** y un cliente generado desde el OpenAPI de Swagger (`openapi-typescript` u `orval`), así los tipos no se desvían del backend.
- **TanStack Query** (datos del servidor), **TanStack Router** o React Router (rutas por rol), **React Hook Form + Zod** (formularios).
- Componentes: **shadcn/ui** (Radix + Tailwind 4) para tener la base accesible y aplicar la identidad Terracota encima. **TanStack Table** para tablas, **Axios** como cliente HTTP (interceptor de refresh), **date-fns**, **lucide-react**, **sonner**.
- Sesión: **Zustand**. Calidad: **Vitest + Testing Library**, **Playwright**, **ESLint (Standard, neostandard)**, **Prettier**.
- **socket.io-client** para el tablero en vivo; Google Maps JS para el mapa.
- Despliegue: build estático en Railway, Cloudflare Pages o Vercel.

**Decisiones**

| # | Decisión | Opciones | Recomendado |
|---|---|---|---|
| 1 | Tecnología | React + Vite · Vue · Next.js · Angular · Flutter Web | ✅ React + Vite |
| 2 | Una web o dos | Una con roles · Admin y Portal Socios separados | Una con roles |
| 3 | Login del admin | OTP por SMS · OTP + contraseña · Google | Por definir |
| 4 | Dominio | `admin.apamuy.pe` / `socios.apamuy.pe` · uno solo | Uno: `panel.apamuy.pe` |

## 7. Identidad visual

El panel hereda [DIRECCION_VISUAL.md](DIRECCION_VISUAL.md): crema `#FBF7F2`, terracota `#B84A2B`, verde hierba `#4E7A40`, texto café `#2A1A14`; Outfit para titulares y cifras, Plus Jakarta Sans para interfaz; base de 4 px; la esquina de salida en tarjetas y botones. Se trasladan como variables CSS (tokens) con modo oscuro de cafés cálidos. Más densidad que en el móvil: es una herramienta de trabajo.

## 8. Plan

| # | Trabajo | Desbloquea |
|---|---|---|
| W0 | ✅ Proyecto, estructura, tokens, ingreso por OTP, portales con guardas, lint de límites, tests y CI. Falta: generar el cliente con orval y la cookie httpOnly en el backend | Empezar |
| W1 | ✅ Socios, catálogo básico (negocios, categorías, horarios, secciones, productos) y Marketing (cupones, banners). Pendiente: editor de variantes/opciones | Dejar Swagger |
| W2 | Backend: imágenes + Admin: fotos del catálogo | Catálogo real |
| W3 | ✅ Backend: `admin/orders` + Admin: pedidos en vivo y alertas. Falta el mapa de repartidores | Vigilar la operación |
| W4 | ✅ Portal Socios: inicio del día, Mi tienda, menú, horarios, reportes y rendición (sin comisión) | Autogestión de negocios |
| W5 | ✅ Caja y ciudades. Pendiente: liquidaciones, después de definir la comisión | Escalar |

## 9. Estructura de `web/`

Acordada el 2026-10-08. Las reglas de trabajo están en [`web/CLAUDE.md`](../web/CLAUDE.md).

```
web/src/
├── main.tsx · index.css            # arranque; Tailwind + tokens Terracota
├── app/
│   ├── providers/                  # providers.tsx · query-client.ts · http-setup.ts
│   ├── router/                     # router.tsx (root, layouts, árbol completo) · guards.ts
│   ├── api/                        # http.ts · interceptors.ts · api-error.ts · generated/ (orval)
│   └── config/                     # env.ts · navigation.ts
├── layouts/                        # root · auth · admin · merchant
├── features/                       # un dominio por carpeta
│   └── <feature>/
│       ├── api/                    # query keys, queries y mutations (envuelven lo generado)
│       ├── components/
│       ├── hooks/
│       ├── layouts/                # layout propio del feature, si lo tiene
│       ├── model/                  # tipos, reglas y lógica pura del cliente
│       ├── pages/                  # *.page.tsx
│       ├── routes/                 # *.routes.tsx: definiciones (path, componente, loader)
│       ├── schemas/                # Zod de formularios
│       └── index.ts                # API pública del feature
├── realtime/                       # socket-client.ts · events.ts · subscriptions.ts
├── components/                     # ui/ (shadcn) · layout/ (sidebar, header) · shared/
├── hooks/                          # hooks reutilizables (use-countdown, use-disclosure…)
├── lib/                            # cn · money · errors · datetime/ (adapter de fechas)
└── test/                           # setup.ts · render.tsx · mocks/
```

Features previstas: `auth`, `home`, `orders`, `partners`, `catalog`, `marketing`, `cities`, `reports`, `settlements`.

**Reglas**
- Las carpetas de un feature tienen siempre esos nombres, pero se crean cuando llega su primer archivo (no hay carpetas vacías). Sin `services/`: su papel lo cumple `api/`.
- Dependencias en un solo sentido: `app/providers, app/router → layouts → features → app/api, app/config, realtime, components, hooks, lib`. Un feature no importa de otro; desde fuera solo se importa su `index.ts`.
- Librerías encerradas tras un adapter o una instancia única: fechas en `lib/datetime` (`DateTimeAdapter`, hoy con date-fns) y HTTP en `app/api` (axios). Cambiar de librería toca un solo lugar; ESLint impide importarlas en otro sitio.
- Rutas en código: cada feature exporta **definiciones** de ruta y `app/router/router.tsx` es el único lugar que las crea y las cuelga bajo cada layout (evita importaciones circulares y deja el mapa completo en un archivo).
- Sufijos: `*.api.ts`, `*.schema(s).ts`, `*.store.ts`, `*.routes.tsx`, `*.page.tsx`. Componentes en kebab-case, hooks con `use-`. Tests junto al archivo (`*.test.ts(x)`), e2e en `web/e2e/`.
- Lógica repetida → custom hook (`src/hooks/` si es genérica, `features/<x>/hooks/` si es del dominio).
- ESLint Standard (`neostandard`) + Prettier (sin `;`, comillas simples). Reglas completas en `web/CLAUDE.md`.

**Sesión.** JWT con un store de **Zustand** (`features/auth/stores/session.store.ts`); Axios con interceptores (Bearer, una sola renovación ante 401, errores como `ApiError`). **Interino:** el backend devuelve el refresh token en el body; hasta pasarlo a una cookie httpOnly (§5.1), el store lo persiste en `localStorage` y el access token vive solo en memoria. Es aceptable para el piloto con pocos usuarios internos; la cookie es el primer cambio del backend antes de abrir el Portal Socios a los negocios.
