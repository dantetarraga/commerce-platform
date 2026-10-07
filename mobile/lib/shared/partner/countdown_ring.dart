import 'dart:async';
import 'dart:math' as math;

import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Tiempo que queda para responder, en un anillo que se vacía. Se pone rojo al
/// acabarse. Deja de contar (y de reconstruirse) al llegar a cero.
class CountdownRing extends StatefulWidget {
  const CountdownRing({required this.deadline, required this.total, this.size = 64, super.key});

  final DateTime deadline;
  final Duration total;
  final double size;

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(CountdownRing old) {
    super.didUpdateWidget(old);
    if (old.deadline != widget.deadline) _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = null;
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_secondsLeft <= 0) {
          _timer?.cancel();
          _timer = null;
        }
        setState(() {});
      });
    }
  }

  int get _secondsLeft => widget.deadline.difference(DateTime.now()).inSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seconds = _secondsLeft.clamp(0, widget.total.inSeconds);
    final fraction = widget.total.inSeconds == 0 ? 0.0 : seconds / widget.total.inSeconds;
    final urgent = seconds <= 120;
    final color = urgent ? context.chaski.danger : scheme.primary;
    final label = Formatters.minutesSeconds(seconds);
    return Semantics(
      label: 'Quedan $label para responder',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _RingPainter(fraction: fraction, color: color, track: scheme.primaryContainer),
          child: Center(
            child: Text(
              label,
              style: AppTypography.price(context, size: widget.size * 0.28).copyWith(color: urgent ? color : scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.color, required this.track});

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas
      ..drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      )
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color || old.track != track;
}
