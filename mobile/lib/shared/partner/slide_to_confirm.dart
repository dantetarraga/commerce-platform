import 'dart:math' as math;

import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Confirmación deslizando la ficha hasta el final, para no marcar una entrega con
/// un toque sin querer. Con lector de pantalla se activa con un toque normal.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    required this.onConfirm,
    this.detail,
    this.busy = false,
    super.key,
  });

  /// La acción: "Lo recogí", "Entregado".
  final String label;

  /// La instrucción de arriba: "Desliza cuando tengas todo".
  final String hint;

  /// Dato a la derecha de la instrucción: "Cobras S/ 28.50".
  final String? detail;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onConfirm;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  static const _height = 64.0;
  static const _knob = 52.0;
  static const _inset = 6.0;
  static const _threshold = 0.85;

  late final AnimationController _chevrons = AnimationController(vsync: this, duration: AppMotion.pulse);
  double _dx = 0;
  var _dragging = false;
  var _armed = false;
  var _nudged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotionOf(context)) {
      _chevrons.stop();
    } else if (!_chevrons.isAnimating) {
      _chevrons.repeat();
    }
  }

  @override
  void dispose() {
    _chevrons.dispose();
    super.dispose();
  }

  void _update(double delta, double max) {
    final dx = (_dx + delta).clamp(0.0, max);
    final armed = dx >= max * _threshold;
    if (armed && !_armed) HapticFeedback.selectionClick().ignore();
    setState(() {
      _dx = dx;
      _armed = armed;
      _dragging = true;
    });
  }

  void _end(double max) {
    if (_armed) {
      HapticFeedback.mediumImpact().ignore();
      setState(() {
        _dx = max;
        _dragging = false;
      });
      widget.onConfirm();
      // La ficha se queda al final mientras la acción corre (`busy`) y vuelve
      // en [didUpdateWidget] cuando termina. Si quien la usa no marca `busy`,
      // vuelve en el siguiente cuadro.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.busy && !_dragging) setState(() => _dx = 0);
      });
    } else {
      setState(() {
        _dx = 0;
        _dragging = false;
      });
    }
    _armed = false;
  }

  /// Un toque no confirma: la ficha asoma hacia la derecha para enseñar el gesto.
  Future<void> _nudge() async {
    setState(() {
      _nudged = true;
      _dx = 28;
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) setState(() => _dx = 0);
  }

  @override
  void didUpdateWidget(SlideToConfirm old) {
    super.didUpdateWidget(old);
    // Terminó la acción (con éxito o no): la ficha vuelve al inicio.
    if (old.busy && !widget.busy) _dx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = !widget.busy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.swipe_right_alt_rounded, size: 18, color: _nudged ? widget.color : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _nudged ? 'Desliza la ficha hasta el final' : widget.hint,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _nudged ? widget.color : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.detail != null) ...[
                const SizedBox(width: 8),
                Text(widget.detail!, style: AppTypography.price(context, size: 16)),
              ],
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final max = constraints.maxWidth - _knob - _inset * 2;
            final progress = max <= 0 ? 0.0 : (widget.busy ? 1.0 : _dx / max);
            return Semantics(
              button: true,
              enabled: enabled,
              label: widget.label,
              hint: widget.hint,
              excludeSemantics: true,
              onTap: enabled ? widget.onConfirm : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? _nudge : null,
                onHorizontalDragUpdate: enabled ? (d) => _update(d.delta.dx, max) : null,
                onHorizontalDragEnd: enabled ? (_) => _end(max) : null,
                onHorizontalDragCancel: enabled ? () => _end(max) : null,
                child: Container(
                  height: _height,
                  width: double.infinity,
                  decoration: BoxDecoration(color: widget.color, borderRadius: AppRadius.button),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Lo recorrido se aclara detrás de la ficha.
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: widget.busy || _dx > 0 ? _inset + _knob / 2 + (widget.busy ? max : _dx) : 0,
                        child: ColoredBox(color: AppColors.blanco.withValues(alpha: 0.18)),
                      ),
                      // La acción, centrada en el tramo libre, se desvanece al avanzar.
                      Positioned.fill(
                        left: _knob + _inset * 2,
                        right: 48,
                        child: Opacity(
                          opacity: (1 - progress * 1.8).clamp(0.0, 1.0),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.blanco, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ExcludeSemantics(child: _Chevrons(animation: _chevrons)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // La meta: se llena cuando soltar ya confirma.
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedContainer(
                            duration: AppMotion.quick,
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _armed ? AppColors.blanco : Colors.transparent,
                              border: Border.all(color: AppColors.blanco.withValues(alpha: 0.7), width: 2),
                            ),
                            child: Icon(Icons.check_rounded, size: 16, color: _armed ? widget.color : AppColors.blanco.withValues(alpha: 0.7)),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: _dragging ? Duration.zero : AppMotion.move,
                        curve: AppMotion.arrive,
                        left: _inset + (widget.busy ? max : _dx),
                        top: _inset,
                        child: Container(
                          width: _knob,
                          height: _knob,
                          decoration: BoxDecoration(
                            color: AppColors.blanco,
                            borderRadius: AppRadius.exit(16),
                            boxShadow: AppShadows.knob,
                          ),
                          child: widget.busy
                              ? Center(child: AppLoader(size: 22, color: widget.color))
                              : Icon(_armed ? Icons.check_rounded : widget.icon, color: widget.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// "›››" que se encienden en ola hacia la meta.
class _Chevrons extends StatelessWidget {
  const _Chevrons({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Opacity(
            opacity: animation.isAnimating ? 0.35 + 0.65 * _wave(animation.value - i * 0.18) : 0.6 + i * 0.2,
            child: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.blanco),
          ),
      ],
    ),
  );

  static double _wave(double t) {
    final x = t - t.floorToDouble();
    return math.max(0, math.sin(x * math.pi * 2));
  }
}
