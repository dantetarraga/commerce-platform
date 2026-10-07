import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Qué hacer tras confirmar.
enum OrderConfirmedAction { track, home }

/// Confirmación del pedido con la ilustración y la mini boleta. Volver atrás
/// equivale a "Seguir mi pedido".
Future<OrderConfirmedAction> showOrderConfirmed(BuildContext context, {required Order order}) async {
  HapticFeedback.mediumImpact().ignore();
  final result = await Navigator.of(context, rootNavigator: true).push<OrderConfirmedAction>(
    PageRouteBuilder(
      transitionDuration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
      pageBuilder: (_, _, _) => _OrderConfirmedPage(order: order),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
  return result ?? OrderConfirmedAction.track;
}

class _OrderConfirmedPage extends StatefulWidget {
  const _OrderConfirmedPage({required this.order});

  final Order order;

  @override
  State<_OrderConfirmedPage> createState() => _OrderConfirmedPageState();
}

class _OrderConfirmedPageState extends State<_OrderConfirmedPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppMotion.breath);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotionOf(context)) {
      _started = true;
      _controller.value = 1;
      return;
    }
    if (_started) return;
    _started = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, [Curve curve = AppMotion.arrive]) =>
      CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: curve));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final order = widget.order;
    final storeName = order.store.name;
    final scheduled = order.scheduledFor;
    final message = scheduled == null
        ? 'Enviamos tu pedido a $storeName. Sigue aquí su confirmación y preparación.'
        : 'Enviamos tu pedido a $storeName para ${Formatters.whenPhrase(scheduled)}. Podrás seguir su confirmación.';
    final text = _interval(0.25, 0.7);
    final card = _interval(0.4, 0.85);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(OrderConfirmedAction.track);
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.lg),
                        child: Semantics(
                          liveRegion: true,
                          container: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppRiveSuccess(),
                              const SizedBox(height: AppSpacing.lg),
                              FadeTransition(
                                opacity: text,
                                child: SlideTransition(
                                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(text),
                                  child: Column(
                                    children: [
                                      Text('¡Pedido enviado!', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        message,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              FadeTransition(
                                opacity: card,
                                child: SlideTransition(
                                  position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(card),
                                  child: _OrderMiniCard(order: order),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
                    child: Column(
                      children: [
                        AppButton(
                          label: 'Seguir mi pedido',
                          onPressed: () => Navigator.of(context).pop(OrderConfirmedAction.track),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppButton.secondary(
                          label: 'Volver a Cerca',
                          onPressed: () => Navigator.of(context).pop(OrderConfirmedAction.home),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderMiniCard extends StatelessWidget {
  const _OrderMiniCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = order.itemCount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.card),
      child: Row(
        children: [
          AppNetworkImage(
            url: order.store.logoUrl,
            width: 48,
            height: 48,
            borderRadius: AppRadius.tile,
            fallbackIcon: Icons.storefront_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido ${order.code}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? 'producto' : 'productos'} · ${Formatters.money(order.total)} · ${order.payment.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
