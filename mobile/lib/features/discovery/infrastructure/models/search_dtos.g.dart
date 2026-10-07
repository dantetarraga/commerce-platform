// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreHitDto _$StoreHitDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoreHitDto', json, ($checkedConvert) {
      final val = StoreHitDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        ratingAvg: $checkedConvert('ratingAvg', (v) => (v as num).toDouble()),
        etaMinutes: $checkedConvert('etaMinutes', (v) => (v as num).toInt()),
        isOpenNow: $checkedConvert('isOpenNow', (v) => v as bool),
        logoUrl: $checkedConvert('logoUrl', (v) => v as String?),
      );
      return val;
    });

ProductHitDto _$ProductHitDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProductHitDto', json, ($checkedConvert) {
      final val = ProductHitDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        price: $checkedConvert(
          'price',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        storeId: $checkedConvert('storeId', (v) => v as String),
        storeName: $checkedConvert('storeName', (v) => v as String),
        imageUrl: $checkedConvert('imageUrl', (v) => v as String?),
        hasChoices: $checkedConvert('hasChoices', (v) => v as bool? ?? false),
      );
      return val;
    });

SearchResponseDto _$SearchResponseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SearchResponseDto', json, ($checkedConvert) {
      final val = SearchResponseDto(
        stores: $checkedConvert(
          'stores',
          (v) => (v as List<dynamic>)
              .map((e) => StoreHitDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        products: $checkedConvert(
          'products',
          (v) => (v as List<dynamic>)
              .map((e) => ProductHitDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });
