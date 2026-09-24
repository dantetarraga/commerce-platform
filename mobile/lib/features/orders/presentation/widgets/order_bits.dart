import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// "1:12 pm": hora corta como la dice la gente.
String clock12(DateTime at) {
  final local = at.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m ${local.hour < 12 ? 'am' : 'pm'}';
}

/// Etiqueta corta del estado para la etiqueta viva ("EN CAMINO").
String statusTag(OrderStatus status) => switch (status) {
  OrderStatus.received => 'RECIBIDO',
  OrderStatus.confirmed => 'CONFIRMADO',
  OrderStatus.preparing => 'PREPARANDO',
  OrderStatus.ready => 'LISTO',
  OrderStatus.courierAssigned => 'RECOGIENDO',
  OrderStatus.onTheWay => 'EN CAMINO',
  OrderStatus.delivered => 'ENTREGADO',
  OrderStatus.cancelled => 'CANCELADO',
};

/// Etiqueta viva: punto cobalto con halo que late + texto en mayúsculas.
class LiveTag extends StatefulWidget {
  const LiveTag({required this.label, this.live = true, this.color, super.key});

  final String label;

  /// Sin latido (entregado/cancelado).
  final bool live;
  final Color? color;

  @override
  State<LiveTag> createState() => _LiveTagState();
}

class _LiveTagState extends State<LiveTag> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LiveTag oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.live && !reduceMotionOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: widget.label.toLowerCase(),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.live)
                    Container(
                      width: 9 + 7 * _pulse.value,
                      height: 9 + 7 * _pulse.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.28 * (1 - _pulse.value * 0.6)),
                      ),
                    ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

/// Botón circular (mensaje, llamar, atrás sobre el mapa). Área táctil de 48.
class CircleAction extends StatelessWidget {
  const CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.elevated = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? background;

  /// Con sombra (sobre el mapa).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: AppSpacing.minTouch,
          child: Center(
            child: Material(
              color: background ?? theme.colorScheme.surface,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: elevated ? AppShadows.soft(theme.brightness) : null),
                  child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Error de carga con copy humano: sin conexión o "algo salió mal".
Widget orderLoadError(Object error, {required String what, required VoidCallback onRetry, bool compact = false}) {
  final offline = error is NetworkFailure;
  return AppEmptyState(
    kind: offline ? AppEmptyKind.offline : AppEmptyKind.error,
    title: offline ? 'Sin conexión' : 'Algo salió mal',
    message: offline
        ? 'No pudimos cargar $what. Revisa tu internet y lo intentamos de nuevo.'
        : 'No pudimos cargar $what. No es tu internet; ya lo estamos revisando.',
    actionLabel: 'Reintentar',
    onAction: onRetry,
    compact: compact,
  );
}

/// Fila de lista agrupada (ícono en círculo gris, texto, chevron).
class GroupedRow extends StatelessWidget {
  const GroupedRow({required this.icon, required this.title, required this.onTap, this.trailing, super.key});

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: context.chaski.raised, shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                ?trailing,
                const SizedBox(width: AppSpacing.xxs),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con borde que agrupa filas separadas por líneas finas.
class GroupedCard extends StatelessWidget {
  const GroupedCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: line),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
