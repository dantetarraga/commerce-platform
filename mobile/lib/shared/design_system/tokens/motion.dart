import 'package:flutter/material.dart';

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

/// Ventana corta tras la primera vez que se pinta [data]. Sirve para animar la
/// entrada escalonada de una lista solo cuando llegan los datos, y no cada vez
/// que un ítem vuelve a construirse al hacer scroll.
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

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.duration + widget.delay);
  late final Animation<double> _progress;
  var _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.duration + widget.delay;
    final start = total == Duration.zero ? 0.0 : widget.delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(parent: _controller, curve: Interval(start, 1, curve: AppMotion.arrive));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.enabled || reduceMotionOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        if (t == 1) return child!;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: widget.offset * (1 - t), child: child),
        );
      },
      child: widget.child,
    );
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
        duration: _pressed ? const Duration(milliseconds: 90) : AppMotion.quick,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
