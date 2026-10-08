import 'package:apamuy/core/network/dto/money_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_dtos.g.dart';

@JsonSerializable()
class ProductVariantDto {
  const ProductVariantDto({required this.id, required this.name, required this.price, required this.isAvailable});

  factory ProductVariantDto.fromJson(Map<String, dynamic> json) => _$ProductVariantDtoFromJson(json);

  final String id;
  final String name;
  final MoneyDto price;
  final bool isAvailable;
}

@JsonSerializable()
class OptionValueDto {
  const OptionValueDto({required this.id, required this.name, required this.priceDelta, required this.isAvailable});

  factory OptionValueDto.fromJson(Map<String, dynamic> json) => _$OptionValueDtoFromJson(json);

  final String id;
  final String name;
  final MoneyDto priceDelta;
  final bool isAvailable;
}

@JsonSerializable()
class ProductOptionDto {
  const ProductOptionDto({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.values,
  });

  factory ProductOptionDto.fromJson(Map<String, dynamic> json) => _$ProductOptionDtoFromJson(json);

  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<OptionValueDto> values;
}

/// Resumen del negocio que viene con el producto (lo necesario para la bolsa).
@JsonSerializable()
class ProductStoreDto {
  const ProductStoreDto({
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.etaMinutes,
    required this.isOpenNow,
    this.logoUrl,
  });

  factory ProductStoreDto.fromJson(Map<String, dynamic> json) => _$ProductStoreDtoFromJson(json);

  final String? logoUrl;
  final MoneyDto deliveryFee;
  final MoneyDto minOrderAmount;
  final int etaMinutes;
  final bool isOpenNow;
}

/// `GET /products/:id`.
@JsonSerializable()
class ProductDetailDto {
  const ProductDetailDto({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.name,
    required this.basePrice,
    required this.isAvailable,
    required this.variants,
    required this.options,
    this.description,
    this.imageUrl,
    this.store,
  });

  factory ProductDetailDto.fromJson(Map<String, dynamic> json) => _$ProductDetailDtoFromJson(json);

  final String id;
  final String storeId;
  final String storeName;
  final String name;
  final String? description;
  final String? imageUrl;
  final MoneyDto basePrice;
  final bool isAvailable;
  final List<ProductVariantDto> variants;
  final List<ProductOptionDto> options;
  final ProductStoreDto? store;
}
