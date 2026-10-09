# Reorganización de mobile

**Estado:** implementada el 8 de octubre de 2026 (etapas 1 a 4).
**Verificación:** `flutter analyze` sin avisos, 322 pruebas en verde (6 de ellas de arquitectura) y APK debug de los dos flavors.

Se atacaron dos problemas distintos:

1. **Composición de las apps** (`app/`, `app_partner/`): nombres asimétricos y rutas mezcladas con UI. Era solo cuestión de mover archivos.
2. **Fronteras entre features**: 16 imports a archivos internos de otras features y ciclos entre `stores`, `discovery`, `products` y `favorites`. Era la deuda real.

Las reglas resultantes están en [mobile/CLAUDE.md](CLAUDE.md) y en el §2 de [ARQUITECTURA.md](../docs/ARQUITECTURA.md); este documento registra qué se cambió y por qué.

## 1. Composición de las apps

### Antes

```text
lib/app/                         ← cliente, sin decirlo en el nombre
  app.dart
  router/ app_router.dart, routes.dart, scaffold_with_nav.dart   ← UI dentro de router/
  purchase_bar/                  ← al mismo nivel que router/
lib/app_partner/
  partner_app.dart
  router/
lib/core/router/route_helpers.dart
```

### Ahora

```text
lib/apps/
├── routing/route_helpers.dart          # materialRoute y routerRefresh, comunes a los dos routers
├── customer/
│   ├── app.dart                        # ApamuyApp
│   ├── router/ (app_router.dart, routes.dart)
│   └── shell/
│       ├── scaffold_with_nav.dart
│       └── purchase_bar/ (open_bag, purchase_bar, purchase_bar_controller, with_purchase_bar)
└── partner/
    ├── partner_app.dart                # PartnerApp
    └── router/ (partner_router.dart, partner_routes.dart)
```

Decisiones:

- **`app/` y `app_partner/` no estaban duplicadas.** Cada raíz solo llama a `AppMaterialDefaults.router(...)` con su título y su router. No se creó clase base ni `bootstrap.dart`.
- **Dos routers**: las rutas, redirecciones y roles son distintos.
- **La barra de compra conectada es parte del shell del cliente**, no de una feature: combina `cart`, `checkout`, `home`, `orders` y `go_router`. Sus piezas visuales (`AppPurchaseBar`, `flyToPurchaseBar`) siguen en el design system.
- **Se conservaron los nombres de archivos, clases y la carpeta `router/`**: la carpeta ya dice de qué app se trata.
- **Pruebas:** `test/app/` pasó a `test/apps/`. Esas pruebas levantan las apps completas con `app_harness` y varias cubren cliente y Socios a la vez, así que no se repartieron por app. `partner_router_test` está en `test/apps/partner/` y `partner_layout_test` en `test/shared/partner/`, junto a `PartnerLayout`.

## 2. Fronteras entre features

Los 16 imports internos eran de tres tipos y cada uno se resolvió de una forma:

| Tipo | Casos | Solución |
|---|---|---|
| Dominio que usa el dominio de otra feature | 12 (checkout, home, merchant_orders, courier_deliveries, products) | Barrels `<feature>_domain.dart` (solo Dart puro): `cart_domain`, `orders_domain`, `products_domain`, `addresses_domain`. El barrel principal los reexporta. |
| Presentación que importa una entidad por ruta profunda | 1 (`payment_brand.dart`) | Importa `cart.dart`. |
| Presentación que usa el repositorio de otra feature | 3 (`home_providers`, `quick_add_product`) | `stores` y `products` exponen `getStoreDetailProvider` y `getProductDetailProvider` (sus casos de uso). `RepeatOrder` recibe `GetProductDetail` en lugar del repositorio. |

Ciclos entre features, todos de presentación:

- **`stores ↔ discovery`**: `CategoryStoresPage` navegaba a `ExplorePage`. Ahora recibe `onSearch` desde el router.
- **`stores ↔ favorites` y `products ↔ favorites`**: los detalles de negocio y producto dibujaban el corazón de favoritos. Ahora reciben un `favorite` opcional; el router les pasa `FavoriteToggle.store(id)` o `FavoriteToggle.product(id)`, un widget nuevo de `favorites`.

Con esto no queda ningún ciclo entre features, ni directo ni transitivo.

**Orders** conserva sus entradas por consumidor (`orders`, `orders_customer`, `orders_staff`, `orders_infrastructure`) más `orders_domain`. `order.dart` ya no reexporta `order_insights.dart` (que lo importaba de vuelta); ahora lo hacen los barrels.

## 3. Limpiezas

- **Home:** se eliminaron los barrels internos `home_header.dart`, `home_sections.dart` y `home_editorial.dart`. Se rompió el ciclo `home_page ↔ repeat_row`: `RepeatRow` recibe `onExplore`.
- **Home tiene `domain/repeat_order.dart`**: repetir un pedido es lógica real, así que se queda y se corrigió ARQUITECTURA.md, que decía "solo presentación".
- **Design system:** `app_navigation_dock.dart` y `app_ticket.dart` importan tokens concretos en lugar de su propio barrel.
- **Mapas:** pasaron a `shared/maps/`, divididos en `delivery_map_adapter.dart` (contrato), `delivery_map.dart` (widget y elección del adaptador), `illustrated_delivery_map.dart` y `google_delivery_map.dart`. El ciclo se debía a que el adaptador de Google usa el ilustrado como respaldo; ahora la dependencia va en un solo sentido.
- **`shared/partner/`** se quedó como estaba: es pequeño y lo consumen features, no la app.
- Las referencias a `mobile/AGENTS.md` y `backend/AGENTS.md`, que no existen, apuntan a los `CLAUDE.md`.

## 4. Prueba de arquitectura

`test/architecture/architecture_test.dart` lee las directivas `import`/`export` de `lib/` y verifica:

- `core` y `shared` no importan features ni `apps`; ninguna feature importa `apps`.
- Entre features solo se importan barrels de la raíz; desde `domain/`, solo `<feature>_domain.dart`.
- `domain/` no importa Flutter, Dio, `json_annotation`, Riverpod ni capas de presentación o infraestructura.
- No hay ciclos entre features.
- Desde `main.dart` no se alcanza ninguna feature de Socios, y desde `main_partner.dart` solo se alcanzan `partner_session`, `merchant_orders`, `courier_deliveries`, `auth` y `orders`.

## 5. Lo que no se cambió

- **Features en lista plana**: agruparlas por app complicaría ubicar `orders` y `auth`.
- **Sin carpetas vacías** para completar el esquema por capas.
- **Un solo paquete Dart.** Cada APK incluye todas las dependencias, también las que solo usa Socios (`audioplayers`, `wakelock_plus`). Si Socios llega a necesitar dependencias nativas pesadas, ese sería el motivo para separar en paquetes con un workspace.

El renombrado de marca y la migración de datos guardados se explican en [el README principal](README.md#identidad-y-datos-guardados).
