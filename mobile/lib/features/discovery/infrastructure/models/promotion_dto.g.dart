// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionDto _$PromotionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PromotionDto', json, ($checkedConvert) {
      final val = PromotionDto(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        imageUrl: $checkedConvert('imageUrl', (v) => v as String),
        subtitle: $checkedConvert('subtitle', (v) => v as String?),
        storeId: $checkedConvert('storeId', (v) => v as String?),
        couponCode: $checkedConvert('couponCode', (v) => v as String?),
      );
      return val;
    });
