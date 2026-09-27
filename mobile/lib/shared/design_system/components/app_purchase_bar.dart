import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// Qué muestra la barra de compra. El design system no conoce carrito ni pedidos: la app
/// traduce su estado a una de estas formas.
sealed class PurchaseBarState {
  const PurchaseBarState();
}

/// Nada que hacer: la barra de compra desaparece.
final class PurchaseBarHidden extends PurchaseBarState {
  const PurchaseBarHidden();
}

/// Hay productos en la bolsa.
final class PurchaseBarCart extends PurchaseBarState {
  const PurchaseBarCart({required this.count, required this.total, this.storeName});

  final int count;
  final Money total;
  final String? storeName;
}

/// Hay un pedido en curso (o recién entregado).
final class PurchaseBarOrder extends PurchaseBarState {
  const PurchaseBarOrder({required this.message, this.eta, this.delivered = false});

  /// "Luis va en camino", "Doña Rosa está preparando tu pedido".
  final String message;

  /// "8 min".
  final String? eta;
  final bool delivered;
}

/// Bolsa flotante en terracota con acción blanca. Cambia de tamaño según su
/// contenido y aparece cuando hay productos o un pedido activo.
///
/// Incrementar [pulse] hace "saltar" el contador (al recibir un producto).
class AppPurchaseBar extends StatefulWidget {
  const AppPurchaseBar({required this.state, required this.onTap, this.pulse = 0, super.key});

  final PurchaseBarState state;
  final VoidCallback onTap;
  final int pulse;

  @override
  State<AppPurchaseBar> createState() => _AppPurchaseBarState();
}

class _AppPurchaseBarState extends State<AppPurchaseBar> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: AppMotion.story);

  @override
  void didUpdateWidget(AppPurchaseBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse && !reduceMotionOf(context)) _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  (String, String?, String) _texts(PurchaseBarState state) => switch (state) {
    PurchaseBarCart(:final total, :final storeName) => (Formatters.money(total), storeName, 'Ver bolsa'),
    PurchaseBarOrder(:final message, :final eta, :final delivered) => (
      message,
      delivered ? '¿Qué tal estuvo?' : null,
      eta ?? (delivered ? 'Calificar' : 'Ver'),
    ),
    PurchaseBarHidden() => ('', null, ''),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    final state = widget.state;
    final visible = state is! PurchaseBarHidden;
    final delivered = state is PurchaseBarOrder && state.delivered;
    const bg = AppColors.terracota;
    const fg = AppColors.blanco;
    final actionBg = delivered ? chaski.success : AppColors.blanco;
    final actionFg = delivered ? scheme.onTertiary : AppColors.terracota;
    final (title, subtitle, action) = _texts(state);
    final reduce = reduceMotionOf(context);
    final count = state is PurchaseBarCart ? state.count : null;

    final pill = Semantics(
      button: true,
      onTap: widget.onTap,
      liveRegion: true,
      label: [
        if (count != null) '$count ${count == 1 ? 'producto' : 'productos'}',
        title,
        ?subtitle,
        action,
      ].join('. '),
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: bg,
          borderRadius: AppRadius.card,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.card,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: count != null && count > 2 ? 72 : 60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
                child: AnimatedSwitcher(
                  duration: reduce ? Duration.zero : AppMotion.base,
                  switchInCurve: AppMotion.arrive,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey('$title$subtitle$action$count'),
                    children: [
                      if (count != null) _Count(pulse: _pulse, count: count, bg: fg, fg: bg) else _Knot(pulse: _pulse, ring: fg),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: fg,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.92)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
                        decoration: BoxDecoration(color: actionBg, borderRadius: AppRadius.button),
                        child: Text(action, style: theme.textTheme.labelLarge?.copyWith(color: actionFg, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final content = visible
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: pill,
          )
        : const SizedBox(width: double.infinity);
    // Sin movimiento, cambiar el tamaño directamente evita iniciar un ticker
    // de duración cero durante el layout de la barra inferior.
    if (reduce) return content;
    return AnimatedSize(
      duration: AppMotion.move,
      curve: AppMotion.arrive,
      alignment: Alignment.bottomCenter,
      child: content,
    );
  }
}

/// Contador de productos: salta al agregar uno.
class _Count extends StatelessWidget {
  const _Count({required this.pulse, required this.count, required this.bg, required this.fg});

  final Animation<double> pulse;
  final int count;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        final scale = t == 0 ? 1.0 : 1 + 0.35 * AppMotion.knot.transform(t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.6);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _Knot extends StatelessWidget {
  const _Knot({required this.pulse, required this.ring});

  final Animation<double> pulse;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final accent = context.chaski.accent;
    return SizedBox.square(
      dimension: 22,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = pulse.value;
          // Salto con sobrepaso + onda que se expande y se apaga.
          final jump = t == 0 ? 1.0 : 1 + 0.45 * AppMotion.knot.transform(t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.6);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (t > 0 && t < 1)
                Container(
                  width: 16 + 28 * t,
                  height: 16 + 28 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 1 - t), width: 2),
                  ),
                ),
              Transform.scale(
                scale: jump,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 2.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
