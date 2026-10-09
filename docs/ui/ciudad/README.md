# Chaski · Ciudad en movimiento

Rediseño implementado en Flutter. [Dirección artística y diagnóstico](../../DIRECCION_VISUAL.md).

## Identidad

Papel cálido, tinta azul, cobalto y lima. Outfit para titulares y cifras, Jakarta para lectura. Esquinas asimétricas, fotografía integrada y una línea con dos giros y estaciones forman la firma visual. El trazo conecta portada, búsqueda, bolsa, onboarding y seguimiento.

La jerarquía cambia según el contenido: portada editorial, accesos de distintas proporciones, un negocio destacado a ancho completo, colecciones compactas y filas de catálogo. La navegación usa un dock de tres estaciones con etiquetas permanentes y acciones accesibles.

## Pantallas reales

Capturas de pruebas de widgets con fuentes, assets y componentes reales. El catálogo usa fotos provisionales de Unsplash; no representa el inventario real de los negocios.

| Inicio | Descubrir | Explorar |
|---|---|---|
| ![Inicio](inicio.png) | ![Colecciones](descubrir.png) | ![Búsqueda](explorar.png) |

| Restaurante | Producto | Bolsa |
|---|---|---|
| ![Restaurante](restaurante.png) | ![Producto](producto.png) | ![Bolsa](bolsa.png) |

| Pago | Seguimiento |
|---|---|
| ![Boleta](checkout.png) | ![Recorrido](seguimiento.png) |

| Onboarding · descubre | Elige | Recibe |
|---|---|---|
| ![Descubre](onboarding_descubre.png) | ![Elige](onboarding_elige.png) | ![Recibe](onboarding_recibe.png) |

| Oscuro | 320 px · texto al 140 % | Tablet |
|---|---|---|
| ![Oscuro](inicio_oscuro.png) | ![Texto ampliado](inicio_compacto.png) | ![Tablet](inicio_tablet.png) |

La app de socios comparte los nuevos tokens y controles, con una composición orientada a operar pedidos y entregas.

| Negocio | Negocio · oscuro | Repartidor |
|---|---|---|
| ![Negocio](socios_negocio_movil.png) | ![Negocio oscuro](socios_negocio_oscuro.png) | ![Repartidor](socios_repartidor_movil.png) |

## Movimiento e interacción

- El onboarding responde al arrastre tanto sobre la ilustración como sobre el texto. La cámara y el trazo siguen al dedo; se puede retroceder y saltar.
- Las tarjetas conservan Hero hacia el restaurante. Los productos mantienen entrada escalonada y selección de variantes.
- Agregar muestra feedback háptico, evita duplicar una petición en curso y traslada la imagen a la bolsa solo después de confirmar el agregado. Cancelar el cambio de negocio no dispara la celebración.
- La bolsa cambia de altura con su contenido, anima el contador y continúa como hoja sobre la pantalla actual.
- La confirmación conserva el archivo Rive local y su alternativa estática.
- El mapa interpola el avance ilustrativo; el estado y la ETA proceden del pedido. La posición dibujada **no es GPS en tiempo real**.
- Movimiento reducido desactiva traslaciones, vuelos y Rive sin retirar información ni acciones. El dock y los botones de agregado exponen acciones al lector de pantalla.

## Arquitectura

Los tokens y componentes viven en `mobile/lib/shared/design_system/`. Las composiciones del inicio y onboarding son widgets propios de sus features. Los repositorios, reglas del carrito, variantes, cotización y métodos de pago existentes se conservan.

`DeliveryMapData` contiene coordenadas y ruta sin tipos de un SDK. `DeliveryMapAdapter` dibuja esos datos y se sustituye mediante `deliveryMapAdapterProvider`. El adaptador actual es ilustrativo; se puede incorporar Google Maps, Mapbox u OpenStreetMap sin acoplar las pantallas a su SDK. Aún faltan un proveedor geográfico y coordenadas reales del repartidor.

## Reproducir las capturas

Desde `mobile/`, con [Rive preparado para la plataforma anfitriona](../../../mobile/assets/animations/README.md):

```sh
flutter test --dart-define=CAPTURE_CITY=true --update-goldens test/apps/city_design_test.dart test/apps/purchase_flow_test.dart test/apps/ui_refresh_test.dart
flutter analyze
flutter test
```

La prueba de compra usa fuentes reales y no oculta errores de desbordamiento. Comprueba selección, agregado, bolsa, dirección, pago, seguimiento y calificación. Las capturas no sustituyen una medición de fluidez en un dispositivo Android físico.

## Resultados · 26 de septiembre de 2026

- `flutter analyze`: sin incidencias.
- `flutter test`: 199 pruebas aprobadas.
- Compra completa en 390 px, tema oscuro y 320 px con texto al 140 %.
- Navegación, onboarding, adaptación de mapas, agregado asíncrono y acciones del lector de pantalla comprobados.
- 17 capturas de Flutter generadas, incluyendo cliente, negocio y repartidor; revisión visual de las composiciones principales.
- APK de depuración compiladas: `app-customer-debug.apk` y `app-partner-debug.apk`, en `mobile/build/app/outputs/flutter-apk/`.

Las compilaciones completan correctamente. `rive_native` emite un aviso sobre el uso de Kotlin Gradle Plugin y la compatibilidad con futuras versiones de Flutter; deberá revisarse al actualizar Flutter/Rive. No se ha medido todavía el rendimiento en un teléfono físico.
