# Apamuy · Ciudad en movimiento

## Diagnóstico

La base funcional es sólida: ya existen carrito persistente, Hero, estados de carga, Rive, tipografías locales y movimiento reducido. El problema es compositivo: todos los bloques tienen un peso parecido; fotos, categorías, títulos y promociones se apilan con el mismo ritmo. El blanco continuo, los radios uniformes y las superficies neutras hacen que la marca dependa del cobalto y del nombre. Agregar más efectos no resuelve esa falta de jerarquía.

## Dirección artística

Apamuy es una conexión rápida y cercana entre los lugares y las personas de Espinar. La personalidad es curiosa, enérgica, precisa y humana. La tecnología aparece en la claridad del recorrido y el feedback, sin imitar un tablero de ciencia ficción ni convertir la identidad local en un adorno folclórico.

1. **Personalidad:** un explorador urbano que conoce su barrio. Frases breves, directas y cálidas; estados verificables y precios claros.
2. **Paleta Terracota (2026-09-27):** crema `#FBF7F2` de fondo, terracota `#B84A2B` como color de marca (portada suave `#F7E6DC`, acción, pestaña activa) y verde hierba `#4E7A40` como único acento (ofertas, envío gratis, lo que pasa ahora; texto blanco encima). Texto en café `#2A1A14`. Sin amarillos, sin lima y sin fondos oscuros en el diseño; el modo oscuro del sistema usa cafés cálidos.
3. **Tipografía:** Outfit para titulares editoriales grandes y cifras; Plus Jakarta Sans para interfaz, etiquetas y párrafos. Ambas locales. Contraste de escala, no cinco familias distintas.
4. **Espaciado:** base de 4 px; márgenes de 20; agrupación 8/12/16; pausas editoriales 32/48. Contenido flexible en móviles pequeños y ancho acotado en tablet.
5. **Iconos:** trazos redondeados, detalles mínimos y áreas interactivas de al menos 48 px. Un pequeño sistema de pictogramas de recorrido identifica la navegación.
6. **Ilustración:** mapas y escenas vectoriales propias, con calles, estaciones y objetos geométricos; fotografías de comida amplias y de buena calidad como material provisional sustituible.
7. **Movimiento:** tocar comprime; elegir conecta; agregar traslada; un estado nuevo avanza. 90–160 ms para respuesta, 240–360 para cambio, 520 para una escena. Movimiento reducido conserva toda la información sin traslaciones ni pulsos.
8. **Forma:** la esquina de salida (una esquina corta abajo a la izquierda) en tarjetas, botones e íconos. El trazo punteado que había antes se quitó el 2026-09-27: los recorridos y avances usan líneas sólidas simples.
9. **Componentes:** portada clara en terracota con la comida en círculo y el trazo, buscador relleno de terracota, categorías de proporciones desiguales, barra inferior clásica (ícono y texto) cuyo indicador activo tiene la esquina de salida, barra de compra terracota y boleta con encabezado terracota y corte en zigzag abajo.
10. **Reconocimiento:** papel + tinta + fotografía recortada, titulares compactos de gran escala, la esquina de salida (una esquina corta abajo a la izquierda: L 24/8, M 22/6, S 16/5) y la línea de recorrido. La combinación debe sobrevivir al quitar el logo.

## Composición y pantallas

- **Inicio:** dirección discreta; una portada editorial que reúne saludo, titular, búsqueda y una imagen; después, accesos de distinto tamaño y una recomendación dominante. Las ofertas y los negocios cercanos tienen presentaciones diferentes. La ubicación y los filtros conservan su significado real.
- **Explorar:** búsqueda funcional, filtros como selectores y resultados que reutilizan las tarjetas del sistema. Cambiar una selección tiene feedback breve; la consulta permanece visible.
- **Restaurante:** foto que continúa desde la tarjeta mediante Hero, cabecera de identidad sobre papel, datos de entrega claros, categorías persistentes y productos con contraste entre imagen y descripción.
- **Producto:** fotografía protagonista, descripción y opciones legibles; precio y acción cercanos. La confirmación de agregado depende del resultado del carrito, no del inicio de una petición.
- **Bolsa y pago:** la bolsa visible acompaña la navegación. Al abrirla, cantidades y totales conservan continuidad con la boleta; el pago mantiene las validaciones y métodos disponibles.
- **Seguimiento:** mapa ilustrado integrado en una abstracción reemplazable, tres roles explícitos (negocio, repartidor, destino), una ruta protagonista y una ficha de ETA. El mapa provisional se identifica como ilustrativo: no se presenta una posición estimada como GPS real.
- **Onboarding:** una misma escena responde continuamente al swipe; las estaciones del recorrido cuentan descubrir, elegir y recibir. El usuario puede avanzar, retroceder y saltar. Rive se reserva para la confirmación satisfactoria ya integrada.
- **Socios:** hereda tipografía, paleta, formas y controles, manteniendo densidad y prioridad operativa para pedidos y entregas.

## Límites de esta implementación

El rediseño preserva repositorios, contratos de API, validaciones y navegación funcional. No añade pasarela de pago ni inventa coordenadas GPS. La abstracción del mapa permite incorporar Google Maps, Mapbox u OpenStreetMap con datos reales posteriormente. Las fotografías provisionales pertenecen exclusivamente al catálogo de demostración; imágenes reales de API y fotografías de perfil conservan prioridad.

## Verificación

Se verificaron capturas reales de Flutter, textos ampliados, tema oscuro, compra y reparto, retorno entre destinos, onboarding y estados de movimiento reducido. Los resultados y capturas están en [la galería del rediseño](ui/ciudad/README.md).
