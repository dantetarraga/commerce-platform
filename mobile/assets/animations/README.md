# Confirmación Rive de Apamuy

`apamuy_success.riv` es una ilustración vectorial propia: círculo cobalto, check blanco, halo y seis destellos lima/azules. No incorpora ilustraciones, fuentes ni imágenes de terceros.

- Artboard: `ApamuySuccess` (240 × 240).
- Animación: `confirm`, una reproducción de 72 fotogramas a 60 fps (1,2 s).
- Peso: **2795 bytes** del archivo; no incluye el peso del runtime nativo.
- Runtime comprobado: `rive 0.14.11` / `rive_native 0.1.11`, renderer de Flutter.

## Fuente y edición

La fuente editable es [`tool/generate_confirmation_rive.dart`](../../tool/generate_confirmation_rive.dart). Genera un archivo binario RIVE 7.0 usando los tipos y propiedades publicados por [rive-runtime](https://github.com/rive-app/rive-runtime/tree/main/include/rive/generated); no es una exportación del editor. El generador es específico de esta escena, no un exportador general. Su compatibilidad se comprueba importando y reproduciendo el archivo con el runtime real en los tests.

Desde `mobile/`:

```sh
dart run tool/generate_confirmation_rive.dart
flutter test test/shared/rive_success_test.dart
```

También se puede sustituir por un archivo exportado desde el editor manteniendo los nombres del artboard y de la animación, sin recursos remotos. Después hay que revisar las capturas y la reproducción con el runtime al actualizar la dependencia o el archivo.

## Comportamiento

`AppRiveSuccess` se comparte entre la confirmación del cliente y el aviso de entrega de Socios. Carga el runtime al primer uso, no bloquea las acciones y detiene su ticker al terminar. Libera la animación, el artboard y el archivo al salir.

Con movimiento reducido o navegación accesible no inicia Rive. Mientras carga, o si falla el archivo/runtime, muestra un check estático construido con Flutter. El texto y el anuncio accesible pertenecen a Flutter; la ilustración es decorativa.

El `.riv` se empaqueta con las dos apps Android. En web, Rive Native puede descargar su módulo WASM; esa plataforma no tiene garantía de funcionamiento sin conexión en el primer uso.

## Preparar las pruebas

Tras `flutter pub get`, instalar las bibliotecas de Rive para la plataforma anfitriona:

```sh
dart run rive_native:setup --platform windows
# En Linux (también se ejecuta en CI):
dart run rive_native:setup --platform linux
```

Los builds de Android realizan su propia preparación. Si en Windows falla `Expand-Archive` por un `PSModulePath` heredado, abrir una consola PowerShell normal o corregir esa variable solo para el proceso antes de ejecutar el setup.

Capturas y validación: [`docs/ui/rive/README.md`](../../../docs/ui/rive/README.md).
