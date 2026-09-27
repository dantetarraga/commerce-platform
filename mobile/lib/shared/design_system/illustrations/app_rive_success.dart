import 'dart:async';

import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Celebración decorativa, local y de una sola reproducción.
/// El texto y las acciones de la pantalla siempre funcionan sin el runtime.
class AppRiveSuccess extends StatelessWidget {
  const AppRiveSuccess({this.size = 168, this.assetPath = asset, super.key});

  static const asset = 'assets/animations/chaski_success.riv';
  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: reduceMotionOf(context) ? const _SuccessStill() : _AnimatedSuccess(key: ValueKey(assetPath), assetPath: assetPath),
      ),
    ),
  );
}

class _SuccessStill extends StatelessWidget {
  const _SuccessStill();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      widthFactor: 0.72,
      heightFactor: 0.72,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primaryContainer),
        child: FractionallySizedBox(
          widthFactor: 0.72,
          heightFactor: 0.72,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
            child: LayoutBuilder(
              builder: (_, constraints) => Icon(Icons.check_rounded, size: constraints.maxWidth * 0.6, color: scheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSuccess extends StatefulWidget {
  const _AnimatedSuccess({required this.assetPath, super.key});

  final String assetPath;

  @override
  State<_AnimatedSuccess> createState() => _AnimatedSuccessState();
}

class _AnimatedSuccessState extends State<_AnimatedSuccess> {
  rive.File? _file;
  rive.Artboard? _artboard;
  _SuccessPainter? _painter;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    rive.File? file;
    rive.Artboard? artboard;
    try {
      // El runtime comparte su inicialización; se difiere hasta el primer uso.
      if (!rive.RiveNative.isInitialized && !await rive.RiveNative.init()) return;
      if (!mounted) return;
      // Esta escena solo necesita formas y transformaciones. El renderer de
      // Flutter permite capturas reales y evita una textura nativa adicional.
      file = await rive.File.asset(widget.assetPath, riveFactory: rive.Factory.flutter);
      if (!mounted) {
        file?.dispose();
        return;
      }
      artboard = file?.artboard('ChaskiSuccess');
      if (artboard == null) throw StateError('No se encontró la ilustración de confirmación.');
      final animation = artboard.animationNamed('confirm');
      if (animation == null) throw StateError('No se encontró la animación de confirmación.');
      final painter = _SuccessPainter(animation);
      setState(() {
        _file = file;
        _artboard = artboard;
        _painter = painter;
      });
    } on Object catch (error) {
      artboard?.dispose();
      file?.dispose();
      // Una ilustración nunca debe impedir continuar un pedido.
      debugPrint('No se pudo cargar la animación de confirmación: $error');
    }
  }

  @override
  void dispose() {
    _painter?.dispose();
    _artboard?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artboard = _artboard;
    final painter = _painter;
    if (artboard == null || painter == null) return const _SuccessStill();
    return RepaintBoundary(
      child: rive.RiveArtboardWidget(artboard: artboard, painter: painter),
    );
  }
}

/// Mantiene el fotograma final sin ticker y libera también la animación nativa.
final class _SuccessPainter extends rive.BasicArtboardPainter {
  _SuccessPainter(this.animation) : super(fit: rive.Fit.contain);

  final rive.Animation animation;

  @override
  bool advance(double elapsedSeconds) => animation.advanceAndApply(elapsedSeconds);

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }
}
