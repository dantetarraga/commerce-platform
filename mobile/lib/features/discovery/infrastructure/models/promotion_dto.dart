import 'package:chaski/features/discovery/domain/promotion.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_dto.g.dart';

@JsonSerializable()
class PromotionDto {
  const PromotionDto({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.storeId,
    this.couponCode,
  });

  factory PromotionDto.fromJson(Map<String, dynamic> json) => _$PromotionDtoFromJson(json);

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? storeId;
  final String? couponCode;

  Promotion toDomain() => Promotion(
    id: id,
    title: title,
    subtitle: subtitle,
    imageUrl: imageUrl,
    storeId: storeId,
    couponCode: couponCode,
  );
}
