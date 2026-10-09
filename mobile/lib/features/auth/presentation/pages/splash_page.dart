import 'dart:math' as math;

import 'package:apamuy/features/auth/presentation/providers/auth_session.dart';
import 'package:apamuy/features/auth/presentation/providers/splash_gate.dart';
import 'package:apamuy/features/auth/presentation/widgets/splash_motion.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

/// Arranque mientras se restaura la sesión: llega la moto, espera andando si
/// tarda y sale acelerando. Al terminar abre [splashGateProvider].
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const name = 'splash';

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: SplashTiming.intro);
  late final _exit = AnimationController(vsync: this, duration: SplashTiming.exit);
  var _started = false;
  var _leaving = false;

  /// Igual que la "A" del arranque nativo (assets/brand/splash_mark.png).
  static const _markSize = 112.0;
  static const _disc = 188.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (ref.read(splashGateProvider)) return;
    if (reduceMotionOf(context)) {
      _intro.value = 1;
      // Tras el primer cuadro: abrir la puerta cambia un provider y no se puede en build.
      WidgetsBinding.instance.addPostFrameCallback((_) => _waitThenLeave());
    } else {
      _intro.forward().whenComplete(_waitThenLeave).ignore();
    }
  }

  void _waitThenLeave() {
    if (!mounted) return;
    ref.listenManual(authSessionProvider, (_, next) {
      if (next.hasValue) _leave().ignore();
    }, fireImmediately: true);
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    if (!reduceMotionOf(context)) await _exit.forward();
    if (mounted) ref.read(splashGateProvider.notifier).open();
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ground = Theme.of(context).scaffoldBackgroundColor;
    final moto = Lottie.asset(AppWaitLoader.asset, animate: !reduceMotionOf(context), errorBuilder: (_, _, _) => const SizedBox());
    return Scaffold(
      backgroundColor: AppColors.terracota,
      body: Semantics(
        label: '$brandName. Lo de tu barrio, en minutos',
        excludeSemantics: true,
        // Arte de marca: no escala con el tamaño de texto del sistema.
        child: MediaQuery.withNoTextScaling(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // El disco nace del centro de la "A".
              final center = constraints.biggest.center(Offset.zero);
              return AnimatedBuilder(
                animation: Listenable.merge([_intro, _exit]),
                builder: (context, _) {
                  final f = SplashFrame.at(intro: _intro.value, exit: _exit.value);
                  final discColor = Color.lerp(AppColors.papel, ground, f.reveal)!;
                  return Stack(
                    children: [
                      if (f.markOpacity > 0)
                        Positioned(
                          left: center.dx - _markSize / 2,
                          top: center.dy - _markSize / 2,
                          child: Opacity(
                            opacity: f.markOpacity,
                            child: const BrandGlyph(size: _markSize),
                          ),
                        ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DiscPainter(
                            center: center,
                            radius: _disc / 2 * f.discScale,
                            reveal: f.reveal,
                            color: discColor,
                          ),
                        ),
                      ),
                      Positioned(
                        left: center.dx - _disc / 2,
                        top: center.dy - _disc / 2,
                        child: ClipOval(
                          child: SizedBox.square(
                            dimension: _disc,
                            child: Transform.translate(
                              offset: Offset(f.riderX * _disc, 0),
                              child: Transform.scale(scale: AppWaitLoader.zoom, alignment: AppWaitLoader.zoomAlignment, child: moto),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: center.dy + _disc / 2 + 22 + f.wordY,
                        child: Opacity(
                          opacity: f.wordOpacity,
                          child: const Center(child: BrandLogo(size: 40, onDark: true)),
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

/// El disco crema de la moto; en la salida crece hasta cubrir la pantalla.
class _DiscPainter extends CustomPainter {
  const _DiscPainter({required this.center, required this.radius, required this.reveal, required this.color});

  final Offset center;
  final double radius;
  final double reveal;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final far = [Offset.zero, size.topRight(Offset.zero), size.bottomLeft(Offset.zero), size.bottomRight(Offset.zero)]
        .map((c) => (c - center).distance)
        .reduce(math.max);
    canvas.drawCircle(center, radius + (far - radius) * reveal, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DiscPainter old) =>
      old.center != center || old.radius != radius || old.reveal != reveal || old.color != color;
}
