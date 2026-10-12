# Interfaz de Apamuy Socios

La tienda prioriza los pedidos que necesitan respuesta, conserva el acceso a preparación, reparto y resumen diario, y permite buscar y filtrar productos por disponibilidad. En tablet, los pedidos se distribuyen en dos columnas si el tamaño del texto lo permite.

El repartidor ve su disponibilidad, los puntos de recogida y entrega, el importe del envío y el cobro al cliente. La entrega activa indica el paso actual y mantiene la acción de confirmar al pie. El resumen diario separa efectivo, Yape y Plin.

Las capturas se generan desde la app real con el backend de demostración. Las imágenes remotas del catálogo pueden mostrar el marcador de carga durante las pruebas; los textos, importes y estados son datos de prueba.

- [Pedidos de tienda](tienda_pedidos.png)
- [Catálogo](tienda_catalogo.png)
- [Pedidos para repartir](repartidor_pedidos.png)
- [Entrega en curso](repartidor_entrega.png)
- [Tienda en tablet y modo oscuro](tienda_tablet_oscuro.png)
- Carta editable: [lista](carta_lista.png), [editar producto](carta_editar.png), [nuevo producto](carta_nuevo.png), [secciones](carta_secciones.png) , [importar desde Excel](carta_importar.png) , [carta vacía](carta_vacia.png), [edición rápida](carta_rapida.png), [elegir varios](carta_elegir.png) y [tablet](carta_tablet.png)

Para regenerarlas, desde `mobile/`:

```sh
flutter test --update-goldens --dart-define=CAPTURE_PARTNER_UI=true test/shared/partner/partner_layout_test.dart
flutter test --update-goldens --dart-define=CAPTURE_PARTNER_UI=true test/features/merchant_catalog/menu_screens_test.dart
```

Las pruebas cubren 390 × 844, 320 × 720 con texto al 140 %, tablet de 1024 × 768 en modo oscuro, búsqueda, filtros, disponibilidad, reanudación de la entrega y el formulario de cobro con teclado abierto.
