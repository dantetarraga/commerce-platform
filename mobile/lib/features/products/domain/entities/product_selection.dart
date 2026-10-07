import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/features/products/domain/entities/product.dart';
import 'package:equatable/equatable.dart';

/// Lo que se arma en el detalle de producto; inmutable. El precio que calcula
/// es orientativo: el backend recalcula siempre.
final class ProductSelection extends Equatable {
  const ProductSelection._({
    required this.product,
    required this.variantId,
    required this.selectedValues,
    required this.quantity,
    required this.notes,
  });

  /// Preselecciona la primera variante disponible; las opciones se eligen a mano.
  factory ProductSelection.initial(Product product) => ProductSelection._(
    product: product,
    variantId: product.variants.where((v) => v.isAvailable).firstOrNull?.id,
    selectedValues: const {},
    quantity: Quantity.one,
    notes: '',
  );

  static const maxNotesLength = 140;

  final Product product;
  final String? variantId;

  /// optionId → ids de valores elegidos.
  final Map<String, Set<String>> selectedValues;
  final Quantity quantity;
  final String notes;

  ProductVariant? get variant => product.variantById(variantId);

  Set<String> selectedIn(String optionId) => selectedValues[optionId] ?? const {};

  bool isSelected(String optionId, String valueId) => selectedIn(optionId).contains(valueId);

  bool canSelectMore(ProductOption option) =>
      option.isSingleChoice || selectedIn(option.id).length < option.maxSelect;

  ProductSelection selectVariant(String id) {
    final target = product.variantById(id);
    if (target == null || !target.isAvailable) return this;
    return _copyWith(variantId: id);
  }

  /// En grupos de una sola elección reemplaza; en los demás agrega o quita
  /// respetando `maxSelect`. Ignora valores no disponibles.
  ProductSelection toggleValue(String optionId, String valueId) {
    final option = product.optionById(optionId);
    final value = option?.valueById(valueId);
    if (option == null || value == null || !value.isAvailable) return this;

    final current = selectedIn(optionId);
    final Set<String> next;
    if (current.contains(valueId)) {
      next = {...current}..remove(valueId);
    } else if (option.isSingleChoice) {
      next = {valueId};
    } else if (current.length < option.maxSelect) {
      next = {...current, valueId};
    } else {
      return this;
    }
    return _copyWith(selectedValues: {...selectedValues, optionId: next});
  }

  ProductSelection withQuantity(Quantity quantity) => _copyWith(quantity: quantity);

  ProductSelection withNotes(String notes) {
    final trimmed = notes.length > maxNotesLength ? notes.substring(0, maxNotesLength) : notes;
    return _copyWith(notes: trimmed);
  }

  List<ProductOption> get missingRequiredOptions =>
      product.options.where((o) => selectedIn(o.id).length < o.minSelect).toList();

  bool get needsVariant => product.hasVariants && variant == null;

  bool get isValid => product.isAvailable && !needsVariant && missingRequiredOptions.isEmpty;

  Money get unitPrice {
    var price = variant?.price ?? product.basePrice;
    for (final option in product.options) {
      for (final valueId in selectedIn(option.id)) {
        final value = option.valueById(valueId);
        if (value != null) price += value.priceDelta;
      }
    }
    return price;
  }

  Money get total => unitPrice * quantity.value;

  ProductSelection _copyWith({
    String? variantId,
    Map<String, Set<String>>? selectedValues,
    Quantity? quantity,
    String? notes,
  }) => ProductSelection._(
    product: product,
    variantId: variantId ?? this.variantId,
    selectedValues: selectedValues ?? this.selectedValues,
    quantity: quantity ?? this.quantity,
    notes: notes ?? this.notes,
  );

  @override
  List<Object?> get props => [product, variantId, selectedValues, quantity, notes];
}
