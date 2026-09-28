# Animaciones Lottie de los estados vacíos

`EmptyArtView` reproduce una vez el `.json` de cada valor de `AppEmptyArt` y queda en su último cuadro (con movimiento reducido aparece ya en ese cuadro). Si un archivo no carga, se muestra el medallón terracota con ícono.

| Archivo | Estado | Original | Autor |
|---|---|---|---|
| `emptyBag.json` | Bolsa o favoritos vacíos | [Shopping](https://lottiefiles.com/animations/shopping-g5VSmWwgIB) | manju |
| `cut.json` | Sin conexión | [No Internet Connection](https://lottiefiles.com/animations/no-internet-connection-MMED6fERQn) | manju |
| `tangle.json` | Error | [cross](https://lottiefiles.com/animations/cross-CFtVpSYnPX) | manju |
| `search.json` | Búsqueda sin resultados | [magnifying glass](https://lottiefiles.com/animations/magnifying-glass-Yd2DLZ5jRC) | faisal qureshi |
| `knot.json` | Confirmado | [Check](https://lottiefiles.com/animations/check-2rfrWCvk6c) | manju |
| `door.json` | Direcciones / entregado | [Delivery](https://lottiefiles.com/animations/delivery-B9580m0j6z) | manju |
| `receipt.json` | Sin pedidos todavía | [Receipt](https://lottiefiles.com/animations/receipt-xK4LNfZyU6) | Akasha Studio |

Todas son gratuitas en LottieFiles bajo la **Lottie Simple License** (uso comercial permitido, sin atribución obligatoria; se deja igual como registro).

## Colores

Los originales sin tocar están en `tool/brand/lottie_src/`. `tool/brand/recolor_empty_lotties.py` los lleva a la paleta (terracota, hierba, papel, tinta) con un mapa por archivo y falla si aparece un color sin mapear:

```sh
python tool/brand/recolor_empty_lotties.py
```

Para cambiar una animación: reemplazar el original en `lottie_src/`, ajustar su mapa de colores, volver a correr el script y revisar el tamaño con `AppEmptyArt.lottieScale` (cada archivo trae su propio encuadre).
