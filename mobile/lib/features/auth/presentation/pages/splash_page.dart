import 'dart:math' as math;

import 'package:chaski/features/auth/presentation/providers/auth_session.dart';
import 'package:chaski/features/auth/presentation/providers/splash_gate.dart';
import 'package:chaski/features/auth/presentation/widgets/splash_motion.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arranque mientras se restaura la sesión: entrada, relevo si tarda y salida.
/// Al terminar abre [splashGateProvider].
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const name = 'splash';

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: SplashTiming.intro);
  late final _loop = AnimationController(vsync: this, duration: SplashTiming.loop);
  late final _exit = AnimationController(vsync: this, duration: SplashTiming.exit);
  var _started = false;
  var _leaving = false;

  static const _markSize = 112.0;
  static const _word = 'apamuy';

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
                  final f = SplashFrame.at(intro: _intro.value, loop: _loop.isAnimating ? _loop.value : null, exit: _exit.value);
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
                                        dot: AppColors.hierba300,
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
                                              style: AppTypography.displayStyle(
                                                context,
                                                size: 44,
                                                height: 1,
                                                weight: FontWeight.w800,
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
