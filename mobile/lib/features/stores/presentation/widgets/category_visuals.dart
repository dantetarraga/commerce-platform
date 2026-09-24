import 'package:flutter/material.dart';

/// Objeto del sticker de cada categoría y su inclinación (varía para que el
/// estante se sienta pegado a mano, no una grilla de íconos). Sin colores por
/// categoría: el estante es tonal y el añil lo pone el objeto.
///
/// Cuando existan fotos recortadas de objetos reales, `AppCategory.image` las
/// usa en lugar del ícono.
({IconData icon, double tilt}) categoryVisuals(String slug) => switch (slug) {
  'restaurantes' => (icon: Icons.soup_kitchen_rounded, tilt: -0.08),
  'mercado' => (icon: Icons.bakery_dining_rounded, tilt: 0.06),
  'bodegas' => (icon: Icons.shopping_basket_rounded, tilt: -0.04),
  'farmacia' => (icon: Icons.medication_rounded, tilt: 0.08),
  'postres' => (icon: Icons.cake_rounded, tilt: -0.06),
  'licores' => (icon: Icons.local_drink_rounded, tilt: 0.05),
  'regalos' => (icon: Icons.local_florist_rounded, tilt: -0.07),
  'encargos' => (icon: Icons.inventory_2_rounded, tilt: 0.07),
  'mascotas' => (icon: Icons.pets_rounded, tilt: -0.05),
  _ => (icon: Icons.storefront_rounded, tilt: 0.0),
};

/// Nombre corto para el estante ("Licores" se muestra como "Bebidas").
String categoryShelfLabel(String slug, String name) => switch (slug) {
  'licores' => 'Bebidas',
  'farmacia' => 'Botica',
  _ => name,
};
