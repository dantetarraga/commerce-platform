# Rive en las dos apps

Capturas del 2026-09-26 generadas por pruebas de widgets de las pantallas reales. El runtime Rive nativo decodifica y pinta el archivo local: no se sustituye por un mock.

| Cliente · claro | Cliente · oscuro |
|---|---|
| ![Pedido enviado en claro](pedido_claro.png) | ![Pedido enviado en oscuro](pedido_oscuro.png) |

| Texto al 140 %, movimiento reducido | Socios · entrega completada |
|---|---|
| ![Confirmación estática accesible](pedido_texto_grande.png) | ![Aviso de entrega con Rive](socios_entrega.png) |

En el cliente, las acciones de seguimiento e inicio siguen disponibles durante la animación. El mensaje indica que el pedido se envió al negocio; no afirma que ya fue aceptado o esté preparándose. En Socios, Rive acompaña al aviso breve después de registrar una entrega correctamente.

## Reproducir

Desde `mobile/`, con el runtime anfitrión preparado según [las instrucciones del asset](../../../mobile/assets/animations/README.md):

```sh
flutter test --dart-define=CAPTURE_RIVE=true --update-goldens test/features/checkout/presentation/order_confirmation_test.dart test/features/courier_deliveries/courier_home_page_test.dart
flutter test test/shared/rive_success_test.dart
```

Las pruebas comprueban la reproducción única y el apagado del ticker, carga fallida, movimiento reducido desde el inicio y activado durante la animación, salida durante la carga, navegación y el flujo completo de entrega. Las capturas de Socios usan datos demo; el número de entregas y sus importes pueden variar con la fecha de ejecución.

Se compilaron las APK debug de ambos sabores. Las capturas provienen del renderer de Flutter en Windows; no constituyen una medición de fluidez, memoria ni peso añadido en dispositivos Android físicos. El build actual termina correctamente y Flutter avisa de una futura incompatibilidad de Kotlin Gradle Plugin en `rive_native`; revisar ese aviso al actualizar Flutter o Rive.
