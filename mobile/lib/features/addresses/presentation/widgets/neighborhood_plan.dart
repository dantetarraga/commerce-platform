import 'package:apamuy/features/addresses/presentation/widgets/door_pin.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Plano del barrio que se arrastra bajo un pin fijo, mientras no haya mapa real.
/// Al cambiar [seed] (la calle) salta a un punto estable y el pin vuelve a caer.
class NeighborhoodPlan extends StatefulWidget {
  const NeighborhoodPlan({required this.seed, this.height = 170, this.onMoved, this.hint, super.key});

  /// Cualquier valor que identifique la dirección escrita (la calle).
  final String seed;
  final double height;

  /// Desplazamiento del plano en px lógicos (para ajustar las coordenadas).
  final ValueChanged<Offset>? onMoved;

  /// Globo sobre el pin ("Mueve el mapa hasta tu puerta").
  final String? hint;

  @override
  State<NeighborhoodPlan> createState() => _NeighborhoodPlanState();
}

class _NeighborhoodPlanState extends State<NeighborhoodPlan> with SingleTickerProviderStateMixin {
  late final _glide = AnimationController(vsync: this, duration: AppMotion.move);
  Offset _offset = Offset.zero;
  Animation<Offset>? _glideTween;
  var _dragging = false;

  @override
  void initState() {
    super.initState();
    _glide.addListener(() {
      final tween = _glideTween;
      if (tween != null) setState(() => _offset = tween.value);
    });
  }

  @override
  void didUpdateWidget(NeighborhoodPlan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed == widget.seed || widget.seed.trim().isEmpty) return;
    final target = _seedOffset(widget.seed);
    if (reduceMotionOf(context)) {
      setState(() => _offset = target);
    } else {
      _glideTween = Tween(begin: _offset, end: target).animate(CurvedAnimation(parent: _glide, curve: AppMotion.arrive));
      _glide.forward(from: 0);
    }
    // Fuera del build: quien escucha puede llamar a setState.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onMoved?.call(target));
  }

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  /// Desplazamiento estable para una calle.
  Offset _seedOffset(String seed) {
    final hash = seed.trim().toLowerCase().codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff);
    return Offset((hash % 160) - 80.0, ((hash ~/ 160) % 120) - 60.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final apamuy = context.apamuy;
    final motion = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;

    return Semantics(
      label: 'Mapa del barrio. Arrastra para ubicar tu puerta bajo el pin.',
      child: SizedBox(
        height: widget.height,
        child: GestureDetector(
          onPanStart: (_) {
            _glide.stop();
            setState(() => _dragging = true);
          },
          onPanUpdate: (d) => setState(() => _offset += d.delta),
          onPanEnd: (_) {
            setState(() => _dragging = false);
            widget.onMoved?.call(_offset);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _PlanPainter(offset: _offset, ground: apamuy.raised, block: scheme.surfaceContainerHigh),
              ),
              // Pin al centro: se levanta al arrastrar y cae al soltar.
              Center(child: LiftingDoorPin(lifted: _dragging)),
              if (widget.hint case final hint?)
                Align(
                  alignment: const Alignment(0, -0.62),
                  child: AnimatedOpacity(
                    duration: motion,
                    opacity: _dragging ? 0 : 1,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: AppRadius.tile),
                        child: Text(hint, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onInverseSurface)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanPainter extends CustomPainter {
  const _PlanPainter({required this.offset, required this.ground, required this.block});

  final Offset offset;
  final Color ground;
  final Color block;

  // Un "tile" de manzanas de 280×230 que se repite al arrastrar.
  static const _tile = Size(280, 230);
  static const _blocks = [
    Rect.fromLTWH(10, 20, 80, 60),
    Rect.fromLTWH(105, 20, 70, 80),
    Rect.fromLTWH(190, 20, 80, 50),
    Rect.fromLTWH(10, 95, 80, 70),
    Rect.fromLTWH(105, 115, 70, 55),
    Rect.fromLTWH(190, 85, 80, 85),
    Rect.fromLTWH(10, 180, 80, 40),
    Rect.fromLTWH(105, 185, 70, 35),
    Rect.fromLTWH(190, 185, 80, 35),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..clipRect(Offset.zero & size)
      ..drawRect(Offset.zero & size, Paint()..color = ground);
    final paint = Paint()..color = block;
    final startX = (offset.dx % _tile.width) - _tile.width;
    final startY = (offset.dy % _tile.height) - _tile.height;
    for (var x = startX; x < size.width; x += _tile.width) {
      for (var y = startY; y < size.height; y += _tile.height) {
        for (final r in _blocks) {
          canvas.drawRRect(RRect.fromRectAndRadius(r.shift(Offset(x, y)), const Radius.circular(8)), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PlanPainter old) => old.offset != offset || old.ground != ground || old.block != block;
}
