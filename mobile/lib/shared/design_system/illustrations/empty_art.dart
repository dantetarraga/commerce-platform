import 'dart:math' as math;

import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Gesto que repite el ícono de un estado vacío, cada pocos segundos.
enum EmptyMotion {
  none,

  /// Flota hacia arriba y vuelve (bolsa, comida lista).
  bob,

  /// Se balancea como una campana (avisos, comandas nuevas).
  ring,

  /// Titila como una llama (en el fogón).
  flicker,

  /// Late (favoritos).
  beat,
}

/// Arte de los estados vacíos: el cuadro con la esquina de salida de la marca
/// y un ícono con su gesto. Mismo lenguaje que el pin del mapa.
enum AppEmptyArt {
  /// Bolsa vacía (carrito sin productos).
  emptyBag(Icons.shopping_bag_rounded, EmptyMotion.bob),

  /// Sin conexión.
  cut(Icons.wifi_off_rounded, EmptyMotion.none),

  /// Algo falló.
  tangle(Icons.error_outline_rounded, EmptyMotion.none),

  /// Sin resultados.
  search(Icons.search_off_rounded, EmptyMotion.none),

  /// Listo, confirmado.
  knot(Icons.check_rounded, EmptyMotion.beat),

  /// Direcciones, entregado.
  door(Icons.home_rounded, EmptyMotion.bob),

  /// Sin pedidos todavía.
  receipt(Icons.receipt_long_rounded, EmptyMotion.none),

  /// Favoritos.
  favorite(Icons.favorite_rounded, EmptyMotion.beat),

  /// Avisos o comandas nuevas.
  bell(Icons.notifications_rounded, EmptyMotion.ring),

  /// En el fogón.
  flame(Icons.local_fire_department_rounded, EmptyMotion.flicker),

  /// Listo para recoger.
  takeout(Icons.takeout_dining_rounded, EmptyMotion.bob),

  /// Productos del menú.
  menu(Icons.restaurant_menu_rounded, EmptyMotion.none),

  /// Entregas del repartidor.
  ride(Icons.two_wheeler_rounded, EmptyMotion.bob);

  const AppEmptyArt(this.icon, this.motion);

  final IconData icon;
  final EmptyMotion motion;
}

/// Dibuja un [AppEmptyArt]: entra con un pequeño rebote y repite su gesto.
/// Con movimiento reducido queda quieto.
class EmptyArtView extends StatelessWidget {
  const EmptyArtView(this.art, {this.size = 96, super.key});

  final AppEmptyArt art;
  final double size;

  /// Pausa entre un gesto y el siguiente.
  static const _rest = Duration(milliseconds: 1800);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = size * 0.29;
    final still = reduceMotionOf(context);
    final icon = Icon(art.icon, size: size * 0.5, color: scheme.primary);
    Widget tile(Widget child) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        // La esquina de salida: abajo a la izquierda, corta.
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(r),
          topRight: Radius.circular(r),
          bottomRight: Radius.circular(r),
          bottomLeft: Radius.circular(size * 0.08),
        ),
      ),
      child: child,
    );
    if (still) return ExcludeSemantics(child: tile(icon));

    final moving = switch (art.motion) {
      EmptyMotion.none => icon,
      EmptyMotion.bob => icon
          .animate(onPlay: (c) => c.repeat())
          .moveY(begin: 0, end: -size * 0.05, duration: AppMotion.pulse ~/ 2, curve: Curves.easeInOut)
          .then()
          .moveY(begin: 0, end: size * 0.05, duration: AppMotion.pulse ~/ 2, curve: Curves.easeInOut)
          .then(delay: _rest ~/ 2),
      EmptyMotion.ring => icon
          .animate(onPlay: (c) => c.repeat())
          .then(delay: _rest)
          .custom(
            duration: const Duration(milliseconds: 700),
            builder: (_, t, child) => Transform.rotate(
              alignment: const Alignment(0, -0.7),
              // Se balancea y se va calmando.
              angle: math.sin(t * math.pi * 4) * (1 - t) * 0.3,
              child: child,
            ),
          ),
      EmptyMotion.flicker => icon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1, end: 1.07, duration: const Duration(milliseconds: 900), curve: Curves.easeInOut, alignment: Alignment.bottomCenter),
      EmptyMotion.beat => icon
          .animate(onPlay: (c) => c.repeat())
          .then(delay: _rest)
          .scaleXY(begin: 1, end: 1.12, duration: AppMotion.quick, curve: Curves.easeOut)
          .then()
          .scaleXY(begin: 1, end: 1 / 1.12, duration: AppMotion.base, curve: Curves.easeIn),
    };
    return ExcludeSemantics(
      child: tile(moving).animate().fadeIn(duration: AppMotion.base, curve: AppMotion.arrive).scaleXY(
        begin: 0.86,
        end: 1,
        duration: AppMotion.story,
        curve: AppMotion.knot,
      ),
    );
  }
}
