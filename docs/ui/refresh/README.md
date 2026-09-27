# Ajustes visuales de ambas apps

Capturas renderizadas desde las pantallas reales y el backend de demostración:

- [Cliente, claro](cliente_movil.png) y [oscuro](cliente_oscuro.png).
- [Negocio, claro](negocio_movil.png) y [oscuro](negocio_oscuro.png).
- [Repartidor conectado](repartidor_movil.png).

Los avatares son assets locales de DiceBear. Las fotos remotas no se descargan en las pruebas de widgets y pueden aparecer en estado de carga. Los nombres, importes y pedidos son datos de prueba.

Regeneración desde `mobile/`:

```sh
flutter test --update-goldens --dart-define=CAPTURE_UI_REFRESH=true test/app/ui_refresh_test.dart
```

La misma prueba comprueba 320 × 720 con texto al 140 %, acceso a la cuenta de Socios y cambio de disponibilidad del repartidor. El detalle de hallazgos y decisiones está en [UI_UX.md](../../UI_UX.md).
