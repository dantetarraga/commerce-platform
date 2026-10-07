import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Sistema de movimiento: rápido al tocar, suave al llegar, siempre hacia adelante.
abstract final class AppMotion {
  /// Presionar (escala 0.97).
  static const tap = Duration(milliseconds: 90);

  /// Chips, toggles, contador.
  static const quick = Duration(milliseconds: 160);

  /// Crossfade de carga, hojas pequeñas.
  static const base = Duration(milliseconds: 240);

  /// Páginas, elementos compartidos, card → barra de compra.
  static const move = Duration(milliseconds: 360);

  /// Onboarding, nudo de confirmación.
  static const story = Duration(milliseconds: 520);

  /// Entrada de una pantalla (transición de página y fundido entre contextos).
  static const page = Duration(milliseconds: 380);

  /// Regreso de una pantalla con la transición de tarjeta que sube.
  static const pageReverse = Duration(milliseconds: 280);

  /// Salida del fundido entre contextos (splash → entrada → app).
  static const fadeThroughReverse = Duration(milliseconds: 260);

  /// Vaivén de error en un campo o formulario.
  static const shake = Duration(milliseconds: 420);

  /// Ciclo de los bucles cortos: pulso "en vivo", brillo del skeleton, cargador.
  static const pulse = Duration(milliseconds: 1400);

  /// Respiración de los nudos y celebración de pedido confirmado.
  static const breath = Duration(milliseconds: 1600);

  /// Bucles lentos de ambiente (punto en vivo de la portada).
  static const ambient = Duration(milliseconds: 2400);

  /// Lo que llega o se asienta.
  static const Curve arrive = Cubic(0.16, 1, 0.3, 1);

  /// Lo que se va (usar ~70 % de la duración de entrada).
  static const Curve depart = Cubic(0.7, 0, 0.84, 0);

  /// Solo nudos y favoritos: leve sobrepaso.
  static const Curve knot = Cubic(0.34, 1.56, 0.64, 1);

  /// Arrastres (hojas, swipe, carrusel).
  static final SpringDescription drag = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: 0.86);
}

/// `true` si el usuario pidió reducir el movimiento (o usa un lector de pantalla).
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) || MediaQuery.accessibleNavigationOf(context);

final _firstSeen = Expando<DateTime>();

/// Ventana corta tras la primera vez que se pinta [data]: anima la entrada de una
/// lista solo al llegar los datos, no en cada rebuild por scroll.
bool entranceWindowOpen(Object data, {Duration window = const Duration(milliseconds: 700)}) {
  final seen = _firstSeen[data] ??= DateTime.now();
  return DateTime.now().difference(seen) < window;
}

/// Entrada con fade + desplazamiento, con retardo opcional para escalonar.
/// Se reproduce una sola vez al montarse.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.move,
    this.offset = const Offset(0, 12),
    this.enabled = true,
    super.key,
  });

  /// Retardo escalonado para el ítem [index] de una lista (con tope).
  FadeSlideIn.staggered({
    required int index,
    required this.child,
    this.enabled = true,
    this.duration = AppMotion.move,
    this.offset = const Offset(0, 12),
    super.key,
  }) : delay = Duration(milliseconds: 45 * index.clamp(0, 8));

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final bool enabled;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  // [FadeSlideIn.enabled] se lee al montarse: si luego cambia, la entrada no
  // se corta ni se repite (y el hijo no pierde su estado).
  late final bool _enabled = widget.enabled;

  @override
  Widget build(BuildContext context) {
    // Activar movimiento reducido a mitad de la entrada la termina al instante.
    if (!_enabled || reduceMotionOf(context)) return widget.child;
    return widget.child
        .animate(delay: widget.delay)
        .fadeIn(duration: widget.duration, curve: AppMotion.arrive)
        .move(begin: widget.offset, end: Offset.zero, duration: widget.duration, curve: AppMotion.arrive);
  }
}

/// Crossfade entre estados de carga (skeleton → datos → error). Cambia de hijo
/// solo cuando cambia [stateKey], así los rebuilds con datos no re-animan.
class LoadCrossFade extends StatelessWidget {
  const LoadCrossFade({required this.stateKey, required this.child, super.key});

  final Object stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
      switchInCurve: AppMotion.arrive,
      switchOutCurve: AppMotion.depart,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

/// Se encoge levemente al presionar: da respuesta táctil a tarjetas y botones.
class PressableScale extends StatefulWidget {
  const PressableScale({required this.child, this.scale = 0.97, super.key});

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  var _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && !reduceMotionOf(context) ? widget.scale : 1,
        duration: reduceMotionOf(context) ? Duration.zero : (_pressed ? AppMotion.tap : AppMotion.quick),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
