import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/core/domain/validated.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/cart/domain/entities/cart.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/products/domain/entities/product.dart';
import 'package:apamuy/features/products/domain/repositories/products_repository.dart';

/// Líneas de bolsa armadas a partir de un pedido anterior y cuántas no se
/// pudieron rearmar (producto agotado, borrado o sin id).
typedef RepeatedOrder = ({List<CartLine> lines, int missing});

/// "Repetir": vuelve a armar las líneas de un pedido con los precios y la
/// disponibilidad de hoy.
class RepeatOrder {
  const RepeatOrder(this._products);

  final ProductsRepository _products;

  Future<RepeatedOrder> call(Order order, {GeoCoordinates? near}) async {
    final ids = {for (final line in order.lines) ?line.productId};
    final fetched = await Future.wait([for (final id in ids) _products.getProduct(id, near: near)]);
    final products = {
      for (final result in fetched)
        if (result case Ok(:final value)) value.id: value,
    };
    return rebuild(order, products, stamp: DateTime.now().microsecondsSinceEpoch);
  }

  /// Arma las líneas con los [products] ya cargados (por id). [stamp] hace
  /// únicos los ids de línea.
  static RepeatedOrder rebuild(Order order, Map<String, Product> products, {required int stamp}) {
    final lines = <CartLine>[];
    var missing = 0;
    for (final (i, line) in order.lines.indexed) {
      final product = line.productId == null ? null : products[line.productId];
      final rebuilt = product == null ? null : _lineFor(line, product, id: '${product.id}.$stamp.$i');
      if (rebuilt == null) {
        missing++;
      } else {
        lines.add(rebuilt);
      }
    }
    return (lines: lines, missing: missing);
  }

  static CartLine? _lineFor(OrderLine line, Product product, {required String id}) {
    final quantity = Quantity.create(line.quantity);
    if (!product.isAvailable || quantity is! Valid<Quantity>) return null;
    // El pedido guarda "Grande · Mote" en la descripción: se busca por nombre y,
    // si no está, la variante del precio pagado o la primera disponible.
    final parts = line.description.split(' · ').map((p) => p.trim()).where((p) => p.isNotEmpty).toSet();
    final paid = line.quantity > 0 ? line.total.cents ~/ line.quantity : line.total.cents;
    final available = product.variants.where((v) => v.isAvailable);
    final variant =
        product.variants.where((v) => parts.contains(v.name)).firstOrNull ??
        available.where((v) => v.price.cents == paid).firstOrNull ??
        available.firstOrNull;
    if (variant != null && !variant.isAvailable) return null;
    if (product.hasVariants && variant == null) return null;
    final choices = [
      for (final option in product.options)
        for (final value in option.values)
          if (parts.contains(value.name) && value.isAvailable)
            CartChoice(optionId: option.id, valueId: value.id, label: value.name, priceDelta: value.priceDelta),
    ];
    return CartLine(
      id: id,
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      variantId: variant?.id,
      variantName: variant?.name,
      choices: choices,
      unitPrice: choices.fold(variant?.price ?? product.basePrice, (sum, c) => sum + c.priceDelta),
      quantity: quantity.value,
      notes: line.notes,
    );
  }
}
