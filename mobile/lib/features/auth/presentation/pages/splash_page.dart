import 'dart:math' as math;

import 'package:chaski/features/auth/presentation/providers/auth_session.dart';
import 'package:chaski/features/auth/presentation/providers/splash_gate.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arranque de Apamuy mientras se restaura la sesión.
///
/// 1. Entrada: el pedido llega volando, la "a" lo atrapa y las letras de "apamuy"
///    saltan una por una.
/// 2. Espera (si la sesión tarda): relevo, un pedido sale y otro llega; las letras
///    hacen una ola en cada llegada.
/// 3. Salida: el pedido se abre hasta cubrir la pantalla con el fondo de la app.
///
/// La "a" queda centrada en pantalla, igual que en el arranque nativo, así el paso
/// del sistema a Flutter no se nota. Al terminar abre [splashGateProvider] y el
/// router sigue.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const name = 'splash';

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  var _started = false;
  var _leaving = false;

  static const _markSize = 112.0;
  static const _word = 'apamuy';

  /// Verde claro: el pedido se lee sobre terracota.
  static const _dot = Color(0xFF9CCB86);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (ref.read(splashGateProvider)) return;
    if (reduceMotionOf(context)) {
      _intro.value = 1;
      // Después del primer cuadro: abrir la puerta cambia un provider y no se puede durante el build.
      WidgetsBinding.instance.addPostFrameCallback((_) => _waitThenLeave());
    } else {
      _intro.forward().whenComplete(_waitThenLeave).ignore();
    }
  }

  void _waitThenLeave() {
    if (!mounted) return;
    if (ref.read(authSessionProvider).hasValue) {
      _leave().ignore();
      return;
    }
    if (!reduceMotionOf(context)) _loop.repeat().ignore();
    ref.listenManual(authSessionProvider, (_, next) {
      if (next.hasValue) _leave().ignore();
    }, fireImmediately: true);
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _loop.stop();
    if (!reduceMotionOf(context)) await _exit.forward();
    if (mounted) ref.read(splashGateProvider.notifier).open();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ground = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: AppColors.terracota,
      body: Semantics(
        label: '$brandName. Lo de tu barrio, en minutos',
        excludeSemantics: true,
        // Arte de marca: no escala con el tamaño de texto del sistema.
        child: MediaQuery.withNoTextScaling(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final center = constraints.biggest.center(Offset.zero);
              const k = _markSize / 100;
              final dotOnScreen = center + (BrandMarkPainter.dotCenter - const Offset(50, 50)) * k;
              return AnimatedBuilder(
                animation: Listenable.merge([_intro, _loop, _exit]),
                builder: (context, _) {
                  final f = _Frame.at(intro: _intro.value, loop: _loop.isAnimating ? _loop.value : null, exit: _exit.value);
                  return Stack(
                    children: [
                      Opacity(
                        opacity: f.contentOpacity,
                        child: Transform.scale(
                          scale: f.contentScale,
                          origin: dotOnScreen - center,
                          child: Stack(
                            children: [
                              Positioned(
                                left: center.dx - _markSize / 2,
                                top: center.dy - _markSize / 2,
                                child: Transform.rotate(
                                  angle: f.bodyAngle,
                                  child: Transform.scale(
                                    scale: f.bodyScale,
                                    child: CustomPaint(
                                      size: const Size.square(_markSize),
                                      painter: BrandMarkPainter(
                                        body: AppColors.papel,
                                        dot: _dot,
                                        dotOffset: f.dotOffset,
                                        dotScale: f.dotScale,
                                        dotOpacity: f.dotOpacity,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: center.dy + _markSize / 2 + 14,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < _word.length; i++)
                                      Opacity(
                                        opacity: f.letterOpacity(i),
                                        child: Transform.translate(
                                          offset: Offset(0, f.letterY(i)),
                                          child: Transform.scale(
                                            scale: f.letterScale(i),
                                            child: Text(
                                              _word[i],
                                              style: const TextStyle(
                                                fontFamily: AppTypography.display,
                                                fontSize: 44,
                                                height: 1,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.papel,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (f.reveal > 0)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RevealPainter(center: dotOnScreen, progress: f.reveal, color: ground),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Un cuadro de la animación, calculado a partir de los tres controladores.
class _Frame {
  _Frame._({
    required this.dotOffset,
    required this.dotScale,
    required this.dotOpacity,
    required this.bodyAngle,
    required this.bodyScale,
    required this.contentOpacity,
    required this.contentScale,
    required this.reveal,
    required double intro,
    required double? loop,
  }) : _intro = intro,
       _loopT = loop;

  factory _Frame.at({required double intro, required double? loop, required double exit}) {
    var dotOffset = Offset.zero;
    var dotScale = 1.0;
    var dotOpacity = 1.0;
    var angle = 0.0;
    var bodyScale = 1.0;

    if (loop == null) {
      // Entrada: el pedido llega desde arriba a la izquierda, se pasa un poco y se asienta.
      final fly = Curves.easeOutCubic.transform(_span(intro, 0, 0.5));
      final settle = Curves.easeOut.transform(_span(intro, 0.5, 0.62));
      dotOffset = Offset.lerp(Offset.lerp(const Offset(-150, -60), const Offset(4, 0), fly), Offset.zero, settle)!;
      dotScale = _lerp(_lerp(0.8, 1.05, fly), 1, settle);
      dotOpacity = _span(intro, 0, 0.2);
      angle = _keys(intro, const [(0.62, 0), (0.72, -6), (0.88, 2), (1, 0)]);
      bodyScale = _keys(intro, const [(0.62, 1), (0.72, 1.04), (0.88, 1), (1, 1)]);
    } else {
      // Relevo: el pedido sale por la derecha y otro entra por la izquierda.
      if (loop < 0.3) {
        final s = Curves.easeIn.transform(loop / 0.3);
        dotOffset = Offset(90 * s, 0);
        dotOpacity = 1 - s;
      } else if (loop < 0.31) {
        dotOpacity = 0;
      } else if (loop < 0.62) {
        final s = Curves.easeOutCubic.transform((loop - 0.31) / 0.31);
        dotOffset = Offset(-120 * (1 - s), 0);
        dotOpacity = s;
      }
      angle = _keys(loop, const [(0.58, 0), (0.66, -5), (0.78, 1.5), (0.9, 0)]);
    }

    final fade = Curves.easeIn.transform(_span(exit, 0, 0.5));
    return _Frame._(
      dotOffset: dotOffset,
      dotScale: dotScale,
      dotOpacity: dotOpacity,
      bodyAngle: angle * math.pi / 180,
      bodyScale: bodyScale,
      contentOpacity: 1 - fade,
      contentScale: 1 + 0.15 * fade,
      reveal: Curves.easeInOutCubic.transform(_span(exit, 0.15, 1)),
      intro: intro,
      loop: loop,
    );
  }

  final Offset dotOffset;
  final double dotScale;
  final double dotOpacity;
  final double bodyAngle;
  final double bodyScale;
  final double contentOpacity;
  final double contentScale;
  final double reveal;
  final double _intro;
  final double? _loopT;

  /// Cada letra salta en cascada cuando la "a" atrapa el pedido.
  double _letterIn(int i) => Curves.easeOutBack.transform(_span(_intro, 0.55 + i * 0.045, 0.85 + i * 0.045));

  double letterOpacity(int i) => _span(_intro, 0.55 + i * 0.045, 0.7 + i * 0.045);

  double letterScale(int i) => 0.6 + 0.4 * _letterIn(i);

  double letterY(int i) {
    final entry = 24 * (1 - _letterIn(i));
    final t = _loopT;
    if (t == null) return entry;
    // Ola: cada letra sube un poco justo después de que llega el pedido.
    final d = (t - (0.62 + i * 0.03)) / 0.075;
    return d.abs() < 1 ? -6 * math.sin((1 - d.abs()) * math.pi / 2) : 0;
  }

  static double _span(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Interpola linealmente entre cuadros clave (tiempo, valor).
  static double _keys(double t, List<(double, double)> keys) {
    if (t <= keys.first.$1) return keys.first.$2;
    for (var i = 1; i < keys.length; i++) {
      final (t1, v1) = keys[i];
      if (t <= t1) {
        final (t0, v0) = keys[i - 1];
        return _lerp(v0, v1, (t - t0) / (t1 - t0));
      }
    }
    return keys.last.$2;
  }
}

/// El pedido que se abre hasta cubrir toda la pantalla.
class _RevealPainter extends CustomPainter {
  const _RevealPainter({required this.center, required this.progress, required this.color});

  final Offset center;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final far = [Offset.zero, size.topRight(Offset.zero), size.bottomLeft(Offset.zero), size.bottomRight(Offset.zero)]
        .map((c) => (c - center).distance)
        .reduce(math.max);
    canvas.drawCircle(center, 7 + (far - 7) * progress, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RevealPainter old) => old.progress != progress || old.center != center || old.color != color;
}
