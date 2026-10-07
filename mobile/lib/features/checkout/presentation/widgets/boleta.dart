import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/checkout/domain/checkout.dart';
import 'package:chaski/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:chaski/features/checkout/presentation/widgets/checkout_info_row.dart';
import 'package:chaski/features/checkout/presentation/widgets/payment_brand.dart';
import 'package:chaski/features/checkout/presentation/widgets/payment_sheet.dart';
import 'package:chaski/features/checkout/presentation/widgets/schedule_sheet.dart';
import 'package:chaski/features/checkout/presentation/widgets/tip_selector.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Tu boleta": el pedido completo en papel de ticketera, con corte en zigzag.
class Boleta extends ConsumerWidget {
  const Boleta({required this.cart, required this.address, required this.draft, required this.issues, required this.total, super.key});

  final Cart cart;
  final Address? address;
  final CheckoutDraft draft;
  final List<CheckoutIssue> issues;
  final Money total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = cart.store;
    final address = this.address;
    final payment = draft.paymentKind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketEdge(top: true),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BoletaHeader(store: store, address: address),
              const SizedBox(height: AppSpacing.lg),
              BoletaLines(cart: cart),
              const SizedBox(height: AppSpacing.xs),
              BoletaTotals(cart: cart, tip: draft.tip, onTipChanged: ref.read(checkoutControllerProvider.notifier).setTip),
            ],
          ),
        ),
        const TicketPerforation(),
        TicketSection(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          child: Column(
            children: [
              CheckoutInfoRow(
                icon: Icons.location_on_outlined,
                caption: 'Entrega',
                title: address == null ? '¿Dónde te lo llevamos?' : '${address.title} · ${address.street}',
                subtitle: address != null && address.reference.isNotEmpty ? address.reference : null,
                action: address == null ? 'Elegir' : 'Cambiar',
                missing: issues.contains(CheckoutIssue.missingAddress),
                onTap: () => showAddressPicker(context),
              ),
              CheckoutInfoRow(
                icon: Icons.schedule_rounded,
                caption: 'Cuándo',
                title: switch (draft.deliveryTime) {
                  DeliverAsap() => 'Ahora · ${Formatters.eta(store?.etaMinutes ?? 30)}',
                  DeliverAt(:final at) => 'Programado, ${Formatters.whenPhrase(at)}',
                },
                subtitle: switch (draft.deliveryTime) {
                  DeliverAsap() => null,
                  DeliverAt() => 'Te avisamos cuando salga',
                },
                action: draft.deliveryTime is DeliverAsap ? 'Programar' : 'Cambiar',
                onTap: () => showScheduleSheet(context, storeName: store?.name),
              ),
              CheckoutInfoRow(
                icon: Icons.account_balance_wallet_outlined,
                leading: payment == null ? null : PaymentLogo(payment, size: 28),
                caption: 'Pago',
                title: payment?.label ?? '¿Cómo pagas?',
                subtitle: draft.paymentHint(cart),
                action: payment == null ? 'Elegir' : 'Cambiar',
                missing: issues.contains(CheckoutIssue.missingPayment) || issues.contains(CheckoutIssue.cashTooLow),
                onTap: () => showPaymentSheet(context, total: total),
              ),
            ],
          ),
        ),
        const TicketPerforation(),
        BoletaFooter(itemCount: cart.itemCount, total: total, paysOnDelivery: payment != null),
        const TicketEdge(top: false),
      ],
    );
  }
}

/// Quién prepara y para dónde va.
class BoletaHeader extends StatelessWidget {
  const BoletaHeader({required this.store, required this.address, super.key});

  final CartStore? store;
  final Address? address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = this.address;
    return Row(
      children: [
        AppNetworkImage(url: store?.logoUrl, width: 48, height: 48, borderRadius: AppRadius.tile, fallbackIcon: Icons.storefront_rounded),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(store?.name ?? '', style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                address == null ? 'Aún sin dirección' : 'Pedido para ${address.street}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Productos ("2× Chairo … S/ 34.80") y la nota para el negocio.
class BoletaLines extends StatelessWidget {
  const BoletaLines({required this.cart, super.key});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amount = theme.textTheme.bodyMedium?.copyWith(fontFeatures: AppTypography.tabularFigures, fontWeight: FontWeight.w600);
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in cart.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Semantics(
              label:
                  '${line.quantity.value} ${line.name}'
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
                        style: muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (cart.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('Nota: “${cart.note}”', style: muted),
          ),
      ],
    );
  }
}

/// Subtotal, envío, cupón y propina (con su selector).
class BoletaTotals extends StatelessWidget {
  const BoletaTotals({required this.cart, required this.tip, required this.onTipChanged, super.key});

  final Cart cart;
  final Money tip;
  final ValueChanged<Money> onTipChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const padding = EdgeInsets.symmetric(vertical: 3);
    final coupon = cart.coupon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmountRow(label: 'Subtotal', amount: cart.subtotal, padding: padding),
        AmountRow(label: 'Envío', amount: cart.deliveryFee, freeLabel: 'Gratis', padding: padding),
        if (coupon != null && !cart.discount.isZero) AmountRow.discount(label: 'Cupón ${coupon.code}', amount: cart.discount, padding: padding),
        AmountRow(label: 'Propina para el repartidor', amount: tip, padding: padding),
        const SizedBox(height: AppSpacing.xxs),
        TipSelector(value: tip, onChanged: onTipChanged),
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
    );
  }
}

/// Pie de la boleta: "TOTAL", cuántos productos y el monto grande.
class BoletaFooter extends StatelessWidget {
  const BoletaFooter({required this.itemCount, required this.total, required this.paysOnDelivery, super.key});

  final int itemCount;
  final Money total;
  final bool paysOnDelivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TicketSection(
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
                    '$itemCount ${itemCount == 1 ? 'producto' : 'productos'}${paysOnDelivery ? ' · pagas al recibir' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedMoney(total, style: AppTypography.price(context, size: 34)),
          ],
        ),
      ),
    );
  }
}

/// Monto que cambia con un pequeño desliz vertical (propina, cupón…).
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(this.amount, {this.style, super.key});

  final Money amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
      switchInCurve: AppMotion.arrive,
      switchOutCurve: AppMotion.depart,
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerRight, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(amount.cents);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: Offset(0, incoming ? 0.5 : -0.5), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(Formatters.money(amount), key: ValueKey(amount.cents), style: style),
    );
  }
}
