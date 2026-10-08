# Revisión de UI/UX de Apamuy y Apamuy Socios

2026-09-26. Revisión de código, capturas renderizadas por Flutter y pruebas con el backend de demostración. No sustituye una prueba de uso con clientes, negocios y repartidores de Espinar.

## Diagnóstico

Las dos apps son entradas del mismo proyecto: `main.dart` y `main_partner.dart`. Comparten un sistema visual con cobalto, lima, fuentes locales, componentes de catálogo y estados vacíos. La base ya incluye `cached_network_image`, `flutter_svg`, `skeletonizer`, DiceBear remoto y animaciones nativas. Agregar paquetes por sí solo no resuelve las principales fricciones.

| Área | Hallazgo | Cambio realizado |
|---|---|---|
| Cliente: inicio | Saludo y pregunta competían en una línea que se truncaba | Saludo secundario y pregunta principal con altura flexible |
| Cliente: promociones | Altura fija; desbordamiento comprobado a 320 px con texto al 140 %. Texto blanco con poco contraste durante la carga | Altura adaptada al texto, títulos limitados a dos líneas y velo cobalto más oscuro |
| Ambas: identidad | Avatar generado dependiente de una petición externa; Socios solo pasaba iniciales | 12 ilustraciones Notionists empaquetadas, selección estable y foto real prioritaria. Misma identidad en la cabecera y la cuenta de Socios |
| Ambas: imágenes | URL vacía intentaba descargar; indicador genérico cuando fallaba la foto | URL vacía tratada como ausencia, fondo de marca y estado «Sin foto» cuando hay espacio; límite de decodificación en miniaturas |
| Ambas: movimiento | El brillo de carga y la transición de fotos ignoraban movimiento reducido | Carga estática y transición inmediata con esa preferencia. La entrada termina si se activa durante la animación |
| Cliente: acciones | Favoritos y agregar tenían 48 px exteriores pero solo 32/34 px interactivos | Toda el área de 48 px responde al toque |
| Cliente: accesibilidad | La semántica de la tarjeta ocultaba el favorito | Acción independiente accesible para guardar sin abrir el negocio |
| Socios: disponibilidad | Un bloque azul grande competía con aceptar/tomar pedido | Tarjeta más discreta, icono y borde verdes al estar disponible, texto explícito y transición breve |
| Socios: cuenta | Identidad poco visible; contenido sin desplazamiento | Avatar, rol, nombre y teléfono agrupados, hoja desplazable |
| Cliente: pagos | El perfil ofrecía tarjeta aunque no está operativa | Texto alineado con efectivo, Yape y Plin al recibir |

## Qué librerías convienen

| Opción | Uso propuesto | Decisión |
|---|---|---|
| [DiceBear Notionists](https://www.dicebear.com/styles/notionists/) + `flutter_svg` | Avatares ilustrados | Integrado mediante assets locales. El estilo es CC0; procedencia en `mobile/assets/avatars/README.md`. Las ilustraciones pueden repetirse y no representan la apariencia real del usuario |
| `cached_network_image` | Fotos reales de productos y negocios | Mantener el paquete existente. El origen y la calidad de las fotos requieren trabajo de catálogo |
| Animaciones nativas + `AppMotion` | Disponibilidad, botones, transiciones y cargas | Mantener la base existente, con movimiento reducido |
| [flutter_animate](https://pub.dev/packages/flutter_animate) | Componer efectos como fade, escala y desplazamiento | Integrado (2026-09-27). `FadeSlideIn`, `AppLoader` y el medallón de los estados vacíos lo usan; `PressableScale` y `LoadCrossFade` siguen con widgets implícitos de Flutter, que ya son cortos |
| [skeletonizer](https://pub.dev/packages/skeletonizer) | Skeletons de carga | Integrado; reemplaza a `shimmer`. `Skeleton`/`SkeletonBox` conservan su API sobre `Skeletonizer.zone`/`Bone`. `AppSkeletonizer` convierte la tarjeta real con datos de relleno (`AppProductRowSkeleton`, `AppStoreCardSkeleton`), así la geometría no se desfasa |
| [toastification](https://pub.dev/packages/toastification) | Avisos breves (`AppToast`) | Integrado solo dentro de `app_toast.dart` (adaptador: ningún otro archivo lo importa). Bajan desde arriba, se apilan hasta dos, se cierran deslizando hacia arriba y se pausan al mantenerlos presionados. Requiere `dependency_overrides` de `equatable` (ver `pubspec.yaml`) |
| `AppLoader` | Carga corta (botones, buscador, interruptores) | Tres puntos que saltan en ola. Reemplaza la barra fina del buscador y los spinners circulares |
| `AppWaitLoader` | Espera de pantalla completa | El repartidor en moto (`assets/animations/moto.json`, Lottie "delivery man bike fast" de LottieFiles, recoloreado con `tool/brand/recolor_lotties.py`). En oscuro va sobre un disco crema. El arranque usa la misma moto: la "a" nativa se abre en un disco, entra la moto y sale acelerando |
| [Rive](https://rive.app/docs/runtimes/flutter/flutter) | Confirmación de pedido y aviso de entrega | Integrado con `rive 0.14.11`, un `.riv` propio local de 2795 bytes y una reproducción de 1,2 s. Componente compartido, alternativa estática, carga diferida y liberación de recursos |
| [Lottie](https://pub.dev/packages/lottie) | Estados vacíos (`AppEmptyArt`) | Integrado con 7 animaciones planas gratuitas de LottieFiles (5 de un mismo autor), recoloreadas a la paleta con `tool/brand/recolor_lotties.py`. Se reproducen una vez; con movimiento reducido muestran el último cuadro. Rive queda para las piezas propias de marca. Procedencia en `mobile/assets/animations/empty/README.md` |

La integración de Rive usa cobalto/lima y mantiene los textos y acciones en Flutter. Con movimiento reducido muestra un check estático y no inicia el runtime. La confirmación ahora dice «Pedido enviado», sin dar por hecha la aceptación del negocio. [Capturas y pruebas](ui/rive/README.md); [fuente editable y preparación del runtime](../mobile/assets/animations/README.md). Todavía no se midieron el peso añadido por el runtime, su memoria ni su fluidez en un teléfono de gama baja.

## Prioridades siguientes

1. **Fotos reales y coherentes.** El catálogo de demo y el seed usan LoremFlickr. Definir fotos de portada, logos y productos, recortes estables y variantes pequeñas servidas desde almacenamiento/CDN. Un proveedor de fotos aleatorias no representa el inventario del negocio.
2. **Completar acciones visibles.** Editar perfil sigue mostrando «Muy pronto» aunque existe el endpoint. GPS y mapa real también están pendientes. Estas expectativas afectan más la confianza que una animación adicional.
3. **Validar con personas.** Observar si el cliente encuentra un producto y entiende el total; si el negocio distingue pedidos nuevos y listos; y si el repartidor identifica qué recoger, dónde entregar y cuánto cobrar.
4. **Validar Rive en hardware.** Medir la primera carga, memoria, fluidez y peso añadido en Android de gama baja antes de extenderlo a más pantallas.

## Verificación y capturas

Las [capturas de la app real](ui/refresh/README.md) usan datos de demostración. Las pruebas de widgets no descargan fotos remotas; en ellas se ven estados de carga. No se sustituyeron por fotos ficticias para las capturas.

Se añadieron regresiones para avatares locales, imágenes vacías, movimiento reducido, acciones accesibles, área táctil completa y pantallas con texto ampliado. También se ejecutan los recorridos existentes de compra, operación del negocio y reparto.

Resultado tras integrar Rive: `flutter analyze` sin incidencias y **187 tests aprobados**, incluyendo el runtime real. Las pruebas existentes de Socios incluyen tablet de 1024 × 768 en modo oscuro y el formulario de cobro con teclado abierto. Se compilaron las APK debug de cliente y Socios. No se midió rendimiento en hardware físico.
