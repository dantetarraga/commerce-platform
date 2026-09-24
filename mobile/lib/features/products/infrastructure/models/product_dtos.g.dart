// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductVariantDto _$ProductVariantDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProductVariantDto', json, ($checkedConvert) {
      final val = ProductVariantDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        price: $checkedConvert(
          'price',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        isAvailable: $checkedConvert('isAvailable', (v) => v as bool),
      );
      return val;
    });

OptionValueDto _$OptionValueDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OptionValueDto', json, ($checkedConvert) {
      final val = OptionValueDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        priceDelta: $checkedConvert(
          'priceDelta',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        isAvailable: $checkedConvert('isAvailable', (v) => v as bool),
      );
      return val;
    });

ProductOptionDto _$ProductOptionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProductOptionDto', json, ($checkedConvert) {
      final val = ProductOptionDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        minSelect: $checkedConvert('minSelect', (v) => (v as num).toInt()),
        maxSelect: $checkedConvert('maxSelect', (v) => (v as num).toInt()),
        values: $checkedConvert(
          'values',
          (v) => (v as List<dynamic>)
              .map((e) => OptionValueDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

ProductStoreDto _$ProductStoreDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProductStoreDto', json, ($checkedConvert) {
      final val = ProductStoreDto(
        deliveryFee: $checkedConvert(
          'deliveryFee',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        minOrderAmount: $checkedConvert(
          'minOrderAmount',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        etaMinutes: $checkedConvert('etaMinutes', (v) => (v as num).toInt()),
        isOpenNow: $checkedConvert('isOpenNow', (v) => v as bool),
        logoUrl: $checkedConvert('logoUrl', (v) => v as String?),
      );
      return val;
    });

ProductDetailDto _$ProductDetailDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProductDetailDto', json, ($checkedConvert) {
      final val = ProductDetailDto(
        id: $checkedConvert('id', (v) => v as String),
        storeId: $checkedConvert('storeId', (v) => v as String),
        storeName: $checkedConvert('storeName', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        basePrice: $checkedConvert(
          'basePrice',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        isAvailable: $checkedConvert('isAvailable', (v) => v as bool),
        variants: $checkedConvert(
          'variants',
          (v) => (v as List<dynamic>)
              .map((e) => ProductVariantDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        options: $checkedConvert(
          'options',
          (v) => (v as List<dynamic>)
              .map((e) => ProductOptionDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        description: $checkedConvert('description', (v) => v as String?),
        imageUrl: $checkedConvert('imageUrl', (v) => v as String?),
        store: $checkedConvert(
          'store',
          (v) => v == null
              ? null
              : ProductStoreDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });
