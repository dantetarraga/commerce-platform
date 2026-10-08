import 'package:apamuy/features/addresses/addresses.dart';
import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:apamuy/features/checkout/presentation/widgets/boleta.dart';
import 'package:apamuy/features/checkout/presentation/widgets/knot_celebration.dart';
import 'package:apamuy/features/checkout/presentation/widgets/payment_sheet.dart';
import 'package:apamuy/features/orders/orders_customer.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Checkout "Tu boleta". Lo último que usaste ya viene elegido.
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({this.onHome, super.key});

  static const name = 'checkout';

  /// "Volver a Cerca" tras confirmar; la provee la app (el feature no conoce
  /// la ruta del inicio). Sin ella, cierra el checkout.
  final VoidCallback? onHome;

  Future<void> _place(BuildContext context, WidgetRef ref) async {
    final order = await ref.read(checkoutControllerProvider.notifier).place();
    if (order == null || !context.mounted) {
      HapticFeedback.heavyImpact().ignore();
      return;
    }
    final router = GoRouter.of(context);
    final action = await showOrderConfirmed(context, order: order);
    switch (action) {
      case OrderConfirmedAction.track:
        await router.pushReplacementNamed(OrderTrackingPage.name, pathParameters: {'orderId': order.id});
      case OrderConfirmedAction.home:
        if (onHome case final onHome?) {
          onHome();
        } else if (router.canPop()) {
          router.pop();
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apamuy = context.apamuy;
    final cart = ref.watch(cartControllerProvider).value ?? Cart.empty;
    final address = ref.watch(selectedAddressProvider);
    final state = ref.watch(checkoutControllerProvider);
    final draft = state.draft;
    final issues = draft.issues(cart, address);
    final total = draft.total(cart);

    if (cart.isEmpty && !state.placing) {
      return Scaffold(
        appBar: AppBar(),
        body: AppEmptyState(
          title: 'Tu bolsa está vacía',
          message: 'Agrega algo antes de confirmar.',
          actionLabel: 'Volver',
          onAction: () => context.pop(),
        ),
      );
    }

    // El botón resuelve lo que falta en vez de quedarse gris.
    final firstIssue = issues.firstOrNull;
    final (String label, VoidCallback? onPressed) = switch (firstIssue) {
      null => (
        draft.deliveryTime is DeliverAt ? 'Programar pedido' : 'Pedir ahora',
        () => _place(context, ref),
      ),
      CheckoutIssue.missingAddress => ('Elegir dirección', () => showAddressPicker(context)),
      CheckoutIssue.missingPayment => ('Elegir cómo pagas', () => showPaymentSheet(context, total: total)),
      CheckoutIssue.cashTooLow => ('Cambiar monto', () => showPaymentSheet(context, total: total)),
      CheckoutIssue.emptyCart || CheckoutIssue.belowMinimum => ('Pedir ahora', null),
    };

    return Scaffold(
      backgroundColor: apamuy.raised,
      appBar: AppBar(
        backgroundColor: apamuy.raised,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('Tu boleta'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xl),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text('Todo listo para salir.', style: Theme.of(context).textTheme.headlineLarge),
          ),
          PrintIn(
            child: Boleta(cart: cart, address: address, draft: draft, issues: issues, total: total),
          ),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: apamuy.raised,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
                  curve: AppMotion.arrive,
                  child: switch ((state.error, firstIssue)) {
                    (final error?, _) => _notice(AppInlineNotice.fromError(error, boxed: false, key: const ValueKey('error'))),
                    (null, final issue?) => _notice(AppInlineNotice(message: issue.message, boxed: false, key: ValueKey(issue))),
                    _ => const SizedBox(width: double.infinity),
                  },
                ),
                AppButton(
                  label: label,
                  trailing: AnimatedMoney(total, style: const TextStyle(fontFeatures: AppTypography.tabularFigures)),
                  loading: state.placing,
                  onPressed: onPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _notice(Widget notice) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: notice);
