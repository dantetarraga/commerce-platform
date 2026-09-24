import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/features/cart/domain/entities/cart.dart';

/// Serialización local de la bolsa. Versionada: si el formato cambia, una
/// bolsa vieja se descarta en vez de romper la app.
abstract final class CartJson {
  static const version = 1;

  static Map<String, Object?> encode(Cart cart) => {
    'v': version,
    'store': switch (cart.store) {
      null => null,
      final s => {
        'id': s.id,
        'name': s.name,
        'logoUrl': s.logoUrl,
        'deliveryFee': s.deliveryFee.cents,
        'minOrderAmount': s.minOrderAmount.cents,
        'etaMinutes': s.etaMinutes,
      },
    },
    'note': cart.note,
    'coupon': switch (cart.coupon) {
      null => null,
      final c => {'code': c.code, 'discount': c.discount.cents, 'label': c.label},
    },
    'lines': [
      for (final l in cart.lines)
        {
          'id': l.id,
          'productId': l.productId,
          'name': l.name,
          'imageUrl': l.imageUrl,
          'variantId': l.variantId,
          'variantName': l.variantName,
          'unitPrice': l.unitPrice.cents,
          'quantity': l.quantity.value,
          'notes': l.notes,
          'choices': [
            for (final c in l.choices)
              {'optionId': c.optionId, 'valueId': c.valueId, 'label': c.label, 'priceDelta': c.priceDelta.cents},
          ],
        },
    ],
  };

  static Cart decode(Object? json) {
    if (json is! Map || json['v'] != version) return Cart.empty;
    try {
      final store = json['store'] as Map?;
      final coupon = json['coupon'] as Map?;
      final lines = (json['lines'] as List).cast<Map<dynamic, dynamic>>();
      return Cart(
        store: store == null
            ? null
            : CartStore(
                id: store['id'] as String,
                name: store['name'] as String,
                logoUrl: store['logoUrl'] as String?,
                deliveryFee: Money(store['deliveryFee'] as int),
                minOrderAmount: Money(store['minOrderAmount'] as int),
                etaMinutes: store['etaMinutes'] as int,
              ),
        coupon: coupon == null
            ? null
            : Coupon(code: coupon['code'] as String, discount: Money(coupon['discount'] as int), label: coupon['label'] as String),
        note: json['note'] as String? ?? '',
        lines: [
          for (final l in lines)
            CartLine(
              id: l['id'] as String,
              productId: l['productId'] as String,
              name: l['name'] as String,
              imageUrl: l['imageUrl'] as String?,
              variantId: l['variantId'] as String?,
              variantName: l['variantName'] as String?,
              unitPrice: Money(l['unitPrice'] as int),
              quantity: Quantity.create(l['quantity'] as int).valueOrNull ?? Quantity.one,
              notes: l['notes'] as String? ?? '',
              choices: [
                for (final c in (l['choices'] as List).cast<Map<dynamic, dynamic>>())
                  CartChoice(
                    optionId: c['optionId'] as String,
                    valueId: c['valueId'] as String,
                    label: c['label'] as String,
                    priceDelta: Money(c['priceDelta'] as int),
                  ),
              ],
            ),
        ],
      );
    } on Object {
      return Cart.empty;
    }
  }
}
