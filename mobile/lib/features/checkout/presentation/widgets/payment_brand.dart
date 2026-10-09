import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Colores de marca de Yape y Plin: son parte de su logo y no cambian con el
/// tema, por eso no están en los tokens.
abstract final class _BrandColors {
  static const yape = Color(0xFF742284);
  static const plin = Color(0xFF00A3E0);
}

extension PaymentKindCopy on PaymentKind {
  String get label => switch (this) {
    PaymentKind.yape => 'Yape',
    PaymentKind.plin => 'Plin',
    PaymentKind.cash => 'Efectivo',
    PaymentKind.card => 'Tarjeta al recibir',
  };

  /// Texto del botón de la hoja: "Usar Yape".
  String get useLabel => switch (this) {
    PaymentKind.yape => 'Usar Yape',
    PaymentKind.plin => 'Usar Plin',
    PaymentKind.cash => 'Usar efectivo',
    PaymentKind.card => 'Usar tarjeta',
  };

  String get hint => switch (this) {
    PaymentKind.yape || PaymentKind.plin => 'Pagas al recibir, al número de quien te lo lleva',
    PaymentKind.cash => '¿Con cuánto pagas? Llevamos el vuelto',
    PaymentKind.card => 'El repartidor lleva POS',
  };
}

extension CheckoutDraftPaymentCopy on CheckoutDraft {
  /// Bajada de la fila "Pago" de la boleta.
  String paymentHint(Cart cart) => switch (paymentKind) {
    PaymentKind.yape || PaymentKind.plin => 'Al número de quien te lo lleva',
    PaymentKind.cash => switch ((cashChangeFor, change(cart))) {
      (null, _) => 'Con el monto exacto',
      (final paysWith?, final change?) => 'Pagas con ${Formatters.money(paysWith)} · vuelto ${Formatters.money(change)}',
      (final paysWith?, null) => 'Con ${Formatters.money(paysWith)} no alcanza',
    },
    PaymentKind.card => 'El repartidor lleva POS',
    null => 'Yape, Plin, efectivo o tarjeta',
  };
}

/// Mosaico con el "logo" del medio de pago.
class PaymentLogo extends StatelessWidget {
  const PaymentLogo(this.kind, {this.size = 36, super.key});

  final PaymentKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final apamuy = context.apamuy;
    final (Color bg, Color fg) = switch (kind) {
      PaymentKind.yape => (_BrandColors.yape, apamuy.onPhoto),
      PaymentKind.plin => (_BrandColors.plin, apamuy.onPhoto),
      PaymentKind.cash => (apamuy.success, scheme.surface),
      PaymentKind.card => (scheme.inverseSurface, scheme.onInverseSurface),
    };
    final text = AppTypography.displayStyle(context, size: size * 0.3, weight: FontWeight.w800, color: fg, height: 1);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
        child: switch (kind) {
          PaymentKind.yape => Text('yape', style: text.copyWith(fontSize: size * 0.3)),
          PaymentKind.plin => Text('plin', style: text.copyWith(fontSize: size * 0.3)),
          PaymentKind.cash => Text('S/', style: text.copyWith(fontSize: size * 0.4)),
          PaymentKind.card => Icon(Icons.credit_card_rounded, size: size * 0.5, color: fg),
        },
      ),
    );
  }
}
