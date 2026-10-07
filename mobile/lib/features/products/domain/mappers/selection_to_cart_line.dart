import 'package:chaski/features/cart/domain/entities/cart.dart';
import 'package:chaski/features/products/domain/entities/product_selection.dart';

/// Traduce lo armado en el detalle de producto a una línea de bolsa.
extension ProductSelectionToCart on ProductSelection {
  CartLine toCartLine() {
    final choices = <CartChoice>[
      for (final option in product.options)
        for (final valueId in selectedIn(option.id))
          if (option.valueById(valueId) case final value?)
            CartChoice(optionId: option.id, valueId: value.id, label: value.name, priceDelta: value.priceDelta),
    ];
    return CartLine(
      id: '${product.id}.${DateTime.now().microsecondsSinceEpoch}',
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      variantId: variant?.id,
      variantName: variant?.name,
      choices: choices,
      unitPrice: unitPrice,
      quantity: quantity,
      notes: notes.trim(),
    );
  }
}
