# Chaski · Flutter

Cliente y Chaski Socios comparten componentes, tokens y datos, con dos puntos de entrada:

```sh
flutter run --flavor customer -t lib/main.dart
flutter run --flavor partner -t lib/main_partner.dart
```

Configuración de entorno en `env/` y `lib/app/config/env.dart`. Añadir el archivo de entorno apropiado con `--dart-define-from-file` según el backend que se quiera usar.

## Diseño

- [Concepto, diagnóstico y sistema visual](../docs/DIRECCION_VISUAL.md).
- [Pantallas y reproducción de capturas](../docs/ui/ciudad/README.md).
- [Fotografías de demostración y sustitución](assets/images/demo/README.md).
- [Asset Rive y preparación de las bibliotecas nativas para pruebas](assets/animations/README.md).

El mapa es ilustrativo. `DeliveryMapAdapter` permite incorporar un proveedor real sin modificar el seguimiento. Las fotografías provisionales corresponden al catálogo demo; la API utiliza sus propias imágenes.
