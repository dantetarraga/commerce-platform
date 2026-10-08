import 'package:apamuy/core/network/dto/money_dto.dart';
import 'package:apamuy/features/discovery/domain/search.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_dtos.g.dart';

@JsonSerializable()
class StoreHitDto {
  const StoreHitDto({
    required this.id,
    required this.name,
    required this.ratingAvg,
    required this.etaMinutes,
    required this.isOpenNow,
    this.logoUrl,
  });

  factory StoreHitDto.fromJson(Map<String, dynamic> json) => _$StoreHitDtoFromJson(json);

  final String id;
  final String name;
  final String? logoUrl;
  final double ratingAvg;
  final int etaMinutes;
  final bool isOpenNow;

  StoreHit toDomain() =>
      StoreHit(id: id, name: name, logoUrl: logoUrl, ratingAvg: ratingAvg, etaMinutes: etaMinutes, isOpenNow: isOpenNow);
}

@JsonSerializable()
class ProductHitDto {
  const ProductHitDto({
    required this.id,
    required this.name,
    required this.price,
    required this.storeId,
    required this.storeName,
    this.imageUrl,
    this.hasChoices = false,
  });

  factory ProductHitDto.fromJson(Map<String, dynamic> json) => _$ProductHitDtoFromJson(json);

  final String id;
  final String name;
  final String? imageUrl;
  final MoneyDto price;
  final String storeId;
  final String storeName;
  @JsonKey(defaultValue: false)
  final bool hasChoices;

  ProductHit toDomain() => ProductHit(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: price.toDomain(),
    storeId: storeId,
    storeName: storeName,
    hasChoices: hasChoices,
  );
}

/// `GET /search?q=&lat=&lng=`.
@JsonSerializable()
class SearchResponseDto {
  const SearchResponseDto({required this.stores, required this.products});

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) => _$SearchResponseDtoFromJson(json);

  final List<StoreHitDto> stores;
  final List<ProductHitDto> products;

  SearchResults toDomain() => SearchResults(
    stores: [for (final s in stores) s.toDomain()],
    products: [for (final p in products) p.toDomain()],
  );
}
