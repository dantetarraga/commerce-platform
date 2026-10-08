import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cantidad "− n +" sobre bloque gris (mismo alto que los botones).
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({required this.quantity, required this.onChanged, this.enabled = true, this.height = 56, super.key});

  final Quantity quantity;
  final ValueChanged<Quantity> onChanged;
  final bool enabled;
  final double height;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  /// El número entra desde abajo al sumar y desde arriba al restar.
  var _increasing = true;

  @override
  void didUpdateWidget(QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity.value != widget.quantity.value) {
      _increasing = widget.quantity.value > oldWidget.quantity.value;
    }
  }

  void _change(Quantity next) {
    HapticFeedback.selectionClick().ignore();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quantity = widget.quantity;
    final enabled = widget.enabled;
    final direction = _increasing ? 1.0 : -1.0;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(color: context.apamuy.raised, borderRadius: AppRadius.button),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Quitar uno',
            color: scheme.onSurface,
            onPressed: enabled && quantity.canDecrement ? () => _change(quantity.decrement()) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 28,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
                transitionBuilder: (child, animation) {
                  // El hijo saliente recorre la animación al revés: sale por el lado opuesto.
                  final incoming = child.key == ValueKey(quantity.value);
                  final begin = Offset(0, (incoming ? 0.6 : -0.6) * direction);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: begin, end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '${quantity.value}',
                  key: ValueKey(quantity.value),
                  textAlign: TextAlign.center,
                  semanticsLabel: 'Cantidad ${quantity.value}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFeatures: AppTypography.tabularFigures,
                    color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Agregar uno',
            color: scheme.onSurface,
            onPressed: enabled && quantity.canIncrement ? () => _change(quantity.increment()) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
