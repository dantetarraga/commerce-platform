# Fotografía provisional

Fotografías descargadas de Unsplash el 2026-09-26 para el catálogo de **demostración** y la portada editorial. No son fotos reales de los comercios ni de sus productos. La [licencia de Unsplash](https://unsplash.com/license) permite su uso en esta aplicación; no son imágenes de Unsplash+.

| Archivo | Fuente original |
|---|---|
| `burger.jpg` | [Unsplash · hamburguesa](https://images.unsplash.com/photo-1568901346375-23c9450c58cd) |
| `table.jpg` | [Unsplash · mesa](https://images.unsplash.com/photo-1504674900247-0877df9cc836) |
| `salad.jpg` | [Unsplash · vegetales](https://images.unsplash.com/photo-1512621776951-a57141f2eefd) |
| `bowl.jpg` | [Unsplash · bowl](https://images.unsplash.com/photo-1546069901-ba9599a7e63c) |
| `grill.jpg` | [Unsplash · parrilla](https://images.unsplash.com/photo-1555939594-58d7cb561ad1) |
| `pizza.jpg` | [Unsplash · pizza](https://images.unsplash.com/photo-1513104890138-7c749659a591) |
| `coffee.jpg` | [Unsplash · café](https://images.unsplash.com/photo-1509042239860-f550ce710b93) |
| `bread.jpg` | [Unsplash · pan](https://images.unsplash.com/photo-1509440159596-0249088772ff) |

Se descargaron a 1000 px de ancho, con `auto=format&fit=crop&w=1000&q=82`. Los archivos se empaquetan con la app para que la demo sea estable sin conexión. Donde no hay una imagen adecuada se conserva el estado visual sin foto, en lugar de descargar una imagen aleatoria.

## Reemplazar imágenes

`AppNetworkImage` acepta tanto una URL HTTPS como una ruta `assets/...`, con la misma geometría y fallback. Las referencias del demo están centralizadas en `assets/fixtures/catalog.json`; sustituirlas por fotos reales no requiere cambiar tarjetas, producto, bolsa ni animación de agregado. La imagen editorial está en `CityCover`. Las respuestas reales de la API conservan sus propias URL y no se reemplazan por estas fotografías.

Los avatares sin foto usan el conjunto local documentado en `assets/avatars/README.md`.
