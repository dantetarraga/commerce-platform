import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Colores de la boleta: papel claro sobre el gris de la pantalla. En oscuro
/// el papel sube un nivel para seguir separándose del fondo.
extension TicketColors on BuildContext {
  Color get ticketPaper {
    final scheme = Theme.of(this).colorScheme;
    return Theme.of(this).brightness == Brightness.dark ? scheme.surfaceContainerHigh : scheme.surface;
  }

  /// Relleno de chips y bloques dentro de la boleta.
  Color get ticketInk {
    final scheme = Theme.of(this).colorScheme;
    return Theme.of(this).brightness == Brightness.dark ? scheme.surfaceContainerHighest : chaski.raised;
  }
}

/// Borde dentado (arriba o abajo) de la boleta, como papel cortado.
class TicketEdge extends StatelessWidget {
  const TicketEdge({required this.top, super.key});

  final bool top;

  static const height = 7.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _ZigzagPainter(color: context.ticketPaper, top: top)),
  );
}

class _ZigzagPainter extends CustomPainter {
  const _ZigzagPainter({required this.color, required this.top});

  final Color color;
  final bool top;

  @override
  void paint(Canvas canvas, Size size) {
    const tooth = 11.0;
    final n = (size.width / tooth).round().clamp(1, 400);
    final step = size.width / n;
    final h = size.height;
    // Dientes hacia afuera: la base toca el cuerpo de la boleta.
    final base = top ? h : 0.0;
    final tip = top ? 0.0 : h;
    final path = Path()..moveTo(0, base);
    for (var i = 0; i < n; i++) {
      path
        ..lineTo(step * i + step / 2, tip)
        ..lineTo(step * (i + 1), base);
    }
    // Un pelo de solape evita una línea fina entre el borde y el cuerpo.
    path
      ..lineTo(size.width, top ? h + 0.5 : -0.5)
      ..lineTo(0, top ? h + 0.5 : -0.5)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ZigzagPainter old) => old.color != color || old.top != top;
}

/// Perforación entre secciones: muescas semicirculares a los lados y una
/// línea punteada, como el troquel de una boleta.
class TicketPerforation extends StatelessWidget {
  const TicketPerforation({super.key});

  static const height = 26.0;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PerforationPainter(paper: context.ticketPaper, dash: Theme.of(context).colorScheme.outline),
      ),
    ),
  );
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({required this.paper, required this.dash});

  final Color paper;
  final Color dash;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final cy = size.height / 2;
    final rect = Path()..addRect(Rect.fromLTWH(0, -0.5, size.width, size.height + 1));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, cy), radius: r))
      ..addOval(Rect.fromCircle(center: Offset(size.width, cy), radius: r));
    canvas.drawPath(Path.combine(PathOperation.difference, rect, holes), Paint()..color = paper);

    final paint = Paint()
      ..color = dash
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashW = 5.0;
    const gap = 5.0;
    var x = r + 10;
    while (x + dashW < size.width - r - 10) {
      canvas.drawLine(Offset(x, cy), Offset(x + dashW, cy), paint);
      x += dashW + gap;
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => old.paper != paper || old.dash != dash;
}

/// Sección de papel de la boleta.
class TicketSection extends StatelessWidget {
  const TicketSection({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.ticketPaper,
    child: Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
      child: child,
    ),
  );
}

/// Fila "nombre ········ precio": los puntos guía corren bajo el nombre y el
/// fondo del texto los tapa, así funcionan con cualquier largo.
class LeaderRow extends StatelessWidget {
  const LeaderRow({required this.label, required this.value, this.leading, super.key});

  final Widget label;
  final Widget value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final paper = context.ticketPaper;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ?leading,
        Expanded(
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 5,
                child: ExcludeSemantics(
                  child: CustomPaint(size: const Size.fromHeight(2), painter: _DotsPainter(Theme.of(context).colorScheme.outline)),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(color: paper),
                child: Padding(padding: const EdgeInsets.only(right: AppSpacing.xs), child: label),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: paper),
          child: Padding(padding: const EdgeInsets.only(left: AppSpacing.xs), child: value),
        ),
      ],
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 1.0; x < size.width; x += 5) {
      canvas.drawCircle(Offset(x, size.height / 2), 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

/// La boleta "sale de la impresora": se revela de arriba hacia abajo mientras
/// el papel baja. Solo la primera vez y sin movimiento si se pidió reducirlo.
class PrintIn extends StatefulWidget {
  const PrintIn({required this.child, super.key});

  final Widget child;

  @override
  State<PrintIn> createState() => _PrintInState();
}

class _PrintInState extends State<PrintIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
  late final Animation<double> _t = CurvedAnimation(parent: _controller, curve: AppMotion.arrive);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotionOf(context)) {
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) {
      final t = _t.value;
      if (t >= 1) return child!;
      return ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 0.08 + 0.92 * t,
          child: Opacity(opacity: (0.4 + t).clamp(0, 1), child: child),
        ),
      );
    },
  );
}
