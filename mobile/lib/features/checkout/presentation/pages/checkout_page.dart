import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/domain/checkout.dart';
import 'package:chaski/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:chaski/features/checkout/presentation/widgets/checkout_format.dart';
import 'package:chaski/features/checkout/presentation/widgets/knot_celebration.dart';
import 'package:chaski/features/checkout/presentation/widgets/payment_brand.dart';
import 'package:chaski/features/checkout/presentation/widgets/payment_sheet.dart';
import 'package:chaski/features/checkout/presentation/widgets/schedule_sheet.dart';
import 'package:chaski/features/checkout/presentation/widgets/ticket.dart';
import 'package:chaski/features/checkout/presentation/widgets/tip_selector.dart';
import 'package:chaski/features/home/home.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Checkout "Tu boleta": todo el pedido en una boleta impresa sobre gris.
/// Lo último que usaste ya viene elegido; solo tocas lo que quieres cambiar.
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  static const name = 'checkout';

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
        router.goNamed(HomePage.name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaski = context.chaski;
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
      backgroundColor: chaski.raised,
      appBar: AppBar(
        backgroundColor: chaski.raised,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('Tu boleta'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xl),
        children: [
          PrintIn(child: _Boleta(cart: cart, address: address, draft: draft, issues: issues)),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: chaski.raised,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
                  curve: AppMotion.postaOut,
                  child: switch ((state.error, firstIssue)) {
                    (final error?, _) => _Notice(key: const ValueKey('error'), message: error.message, danger: true),
                    (null, final issue?) => _Notice(key: ValueKey(issue), message: issue.message),
                    _ => const SizedBox(width: double.infinity),
                  },
                ),
                AppButton(
                  label: label,
                  trailing: _AnimatedTotal(total: total, style: const TextStyle(fontFeatures: AppTypography.tabularFigures)),
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

/// Aviso sobre el botón: qué falta (neutro) o qué salió mal (rojo).
class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.danger = false, super.key});

  final String message;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger ? context.chaski.danger : theme.colorScheme.onSurface;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(danger ? Icons.error_outline_rounded : Icons.info_outline_rounded, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

/// Monto que cambia con un pequeño desliz vertical (propina, cupón…).
class _AnimatedTotal extends StatelessWidget {
  const _AnimatedTotal({required this.total, this.style});

  final Money total;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
      switchInCurve: AppMotion.postaOut,
      switchOutCurve: AppMotion.postaIn,
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerRight, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(total.cents);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: Offset(0, incoming ? 0.5 : -0.5), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(Formatters.money(total), key: ValueKey(total.cents), style: style),
    );
  }
}

class _Boleta extends ConsumerWidget {
  const _Boleta({required this.cart, required this.address, required this.draft, required this.issues});

  final Cart cart;
  final Address? address;
  final CheckoutDraft draft;
  final List<CheckoutIssue> issues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    final controller = ref.read(checkoutControllerProvider.notifier);
    final store = cart.store;
    final total = draft.total(cart);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final amount = theme.textTheme.bodyMedium?.copyWith(fontFeatures: AppTypography.tabularFigures, fontWeight: FontWeight.w600);

    Widget summary(String label, String value, {Color? color, IconData? icon}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: AppSpacing.xxs)],
          Expanded(child: Text(label, style: muted?.copyWith(color: color))),
          Text(value, style: amount?.copyWith(color: color)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketEdge(top: true),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera: quién prepara y para dónde va.
              Row(
                children: [
                  AppNetworkImage(
                    url: store?.logoUrl,
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
                        Text('BOLETA DE PEDIDO', style: AppTypography.eyebrow(context)),
                        const SizedBox(height: 2),
                        Text(store?.name ?? '', style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          address == null ? 'Aún sin dirección' : 'Pedido para ${address!.street}',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Productos.
              for (final line in cart.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Semantics(
                    label: '${line.quantity.value} ${line.name}'
                        '${line.description.isEmpty ? '' : ', ${line.description}'}, ${spokenMoney(line.total)}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LeaderRow(
                          leading: SizedBox(
                            width: 30,
                            child: Text(
                              '${line.quantity.value}×',
                              style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontFeatures: AppTypography.tabularFigures),
                            ),
                          ),
                          label: Text(line.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                          value: Text(Formatters.money(line.total), style: amount),
                        ),
                        if (line.description.isNotEmpty || line.notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 30, top: 2),
                            child: Text(
                              [if (line.description.isNotEmpty) line.description, if (line.notes.isNotEmpty) '“${line.notes}”'].join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (cart.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text('Nota: “${cart.note}”', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              const SizedBox(height: AppSpacing.xs),
              summary('Subtotal', Formatters.money(cart.subtotal)),
              if (cart.deliveryFee.isZero)
                summary('Envío', 'Gratis', color: chaski.success)
              else
                summary('Envío', Formatters.money(cart.deliveryFee)),
              if (!cart.discount.isZero)
                summary('Cupón ${cart.coupon!.code}', '− ${Formatters.money(cart.discount)}', color: chaski.success, icon: Icons.local_offer_rounded),
              summary('Propina para el repartidor', draft.tip.isZero ? '—' : Formatters.money(draft.tip)),
              const SizedBox(height: AppSpacing.xxs),
              TipSelector(value: draft.tip, onChanged: controller.setTip),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 14, color: scheme.primary),
                    const SizedBox(width: AppSpacing.xxs),
                    Flexible(
                      child: Text('100 % para quien te lo lleva', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const TicketPerforation(),
        TicketSection(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.location_on_outlined,
                caption: 'Entrega',
                title: address == null ? '¿Dónde te lo llevamos?' : '${address!.title} · ${address!.street}',
                subtitle: address?.reference.isNotEmpty ?? false ? address!.reference : null,
                action: address == null ? 'Elegir' : 'Cambiar',
                missing: issues.contains(CheckoutIssue.missingAddress),
                onTap: () => showAddressPicker(context),
              ),
              _InfoRow(
                icon: Icons.schedule_rounded,
                caption: 'Cuándo',
                title: switch (draft.deliveryTime) {
                  DeliverAsap() => 'Ahora · ${CheckoutFormat.eta(store?.etaMinutes ?? 30)}',
                  DeliverAt(:final at) => 'Programado, ${CheckoutFormat.whenPhrase(at, DateTime.now())}',
                },
                subtitle: switch (draft.deliveryTime) {
                  DeliverAsap() => null,
                  DeliverAt() => 'Te avisamos cuando salga',
                },
                action: draft.deliveryTime is DeliverAsap ? 'Programar' : 'Cambiar',
                onTap: () => showScheduleSheet(context, storeName: store?.name),
              ),
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                leading: draft.paymentKind == null ? null : PaymentLogo(draft.paymentKind!, size: 28),
                caption: 'Pago',
                title: draft.paymentKind?.label ?? '¿Cómo pagas?',
                subtitle: _paymentHint(draft, cart),
                action: draft.paymentKind == null ? 'Elegir' : 'Cambiar',
                missing: issues.contains(CheckoutIssue.missingPayment) || issues.contains(CheckoutIssue.cashTooLow),
                onTap: () => showPaymentSheet(context, total: total),
              ),
            ],
          ),
        ),
        const TicketPerforation(),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
          child: Semantics(
            label: 'Total ${spokenMoney(total)}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL', style: AppTypography.eyebrow(context)),
                      const SizedBox(height: 2),
                      Text(
                        '${cart.itemCount} ${cart.itemCount == 1 ? 'producto' : 'productos'}'
                        '${draft.paymentKind == null ? '' : ' · pagas al recibir'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _AnimatedTotal(total: total, style: AppTypography.price(context, size: 34)),
              ],
            ),
          ),
        ),
        const TicketEdge(top: false),
      ],
    );
  }

  String? _paymentHint(CheckoutDraft draft, Cart cart) => switch (draft.paymentKind) {
    PaymentKind.yape || PaymentKind.plin => 'Al número de quien te lo lleva',
    PaymentKind.cash => switch ((draft.cashChangeFor, draft.change(cart))) {
      (null, _) => 'Con el monto exacto',
      (final paysWith?, final change?) => 'Pagas con ${Formatters.money(paysWith)} · vuelto ${Formatters.money(change)}',
      (final paysWith?, null) => 'Con ${Formatters.money(paysWith)} no alcanza',
    },
    PaymentKind.card => 'El repartidor lleva POS',
    null => 'Yape, Plin, efectivo o tarjeta',
  };
}

/// Fila de la boleta: ícono, qué es, el valor y la acción a la derecha.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.caption,
    required this.title,
    required this.action,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.missing = false,
  });

  final IconData icon;
  final Widget? leading;
  final String caption;
  final String title;
  final String? subtitle;
  final String action;
  final bool missing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final danger = context.chaski.danger;
    return Semantics(
      button: true,
      label: '$caption: $title${subtitle == null ? '' : ', $subtitle'}${missing ? ', falta' : ''}',
      hint: action,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.tile,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: leading ?? Icon(icon, size: 22, color: missing ? danger : scheme.onSurfaceVariant),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(caption.toUpperCase(), style: AppTypography.eyebrow(context).copyWith(fontSize: 10)),
                          if (missing) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: danger.withValues(alpha: 0.12),
                                borderRadius: const BorderRadius.all(AppRadius.pill),
                              ),
                              child: Text('Falta', style: theme.textTheme.labelSmall?.copyWith(color: danger)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppTypography.tabularFigures),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(action, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
