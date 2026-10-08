import 'package:apamuy/core/domain/money.dart';
import 'package:equatable/equatable.dart';

final class ProductVariant extends Equatable {
  const ProductVariant({required this.id, required this.name, required this.price, required this.isAvailable});

  final String id;
  final String name;

  /// Precio absoluto de la variante (reemplaza al precio base).
  final Money price;
  final bool isAvailable;

  @override
  List<Object?> get props => [id, name, price, isAvailable];
}

final class OptionValue extends Equatable {
  const OptionValue({required this.id, required this.name, required this.priceDelta, required this.isAvailable});

  final String id;
  final String name;
  final Money priceDelta;
  final bool isAvailable;

  @override
  List<Object?> get props => [id, name, priceDelta, isAvailable];
}

/// Grupo de opciones ("Elige tu salsa", "Extras") con mínimo y máximo de elecciones.
final class ProductOption extends Equatable {
  const ProductOption({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.values,
  });

  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<OptionValue> values;

  bool get isRequired => minSelect > 0;
  bool get isSingleChoice => maxSelect == 1;

  OptionValue? valueById(String valueId) => values.where((v) => v.id == valueId).firstOrNull;

  @override
  List<Object?> get props => [id, name, minSelect, maxSelect, values];
}

/// Datos del negocio que el detalle de producto necesita (envío, mínimo,
/// si está abierto) sin depender del feature `stores`.
final class ProductStore extends Equatable {
  const ProductStore({
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.etaMinutes,
    required this.isOpenNow,
    this.logoUrl,
  });

  final String? logoUrl;
  final Money deliveryFee;
  final Money minOrderAmount;
  final int etaMinutes;
  final bool isOpenNow;

  @override
  List<Object?> get props => [logoUrl, deliveryFee, minOrderAmount, etaMinutes, isOpenNow];
}

final class Product extends Equatable {
  const Product({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.name,
    required this.basePrice,
    required this.isAvailable,
    this.description,
    this.imageUrl,
    this.variants = const [],
    this.options = const [],
    this.store,
  });

  final String id;
  final String storeId;
  final String storeName;
  final String name;
  final String? description;
  final String? imageUrl;
  final Money basePrice;
  final bool isAvailable;
  final List<ProductVariant> variants;
  final List<ProductOption> options;
  final ProductStore? store;

  bool get hasVariants => variants.isNotEmpty;

  ProductVariant? variantById(String? variantId) => variants.where((v) => v.id == variantId).firstOrNull;

  ProductOption? optionById(String optionId) => options.where((o) => o.id == optionId).firstOrNull;

  @override
  List<Object?> get props => [id, storeId, storeName, name, description, imageUrl, basePrice, isAvailable, variants, options, store];
}
