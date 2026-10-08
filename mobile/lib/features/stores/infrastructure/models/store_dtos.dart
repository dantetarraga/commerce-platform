import 'package:chaski/core/network/dto/money_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'store_dtos.g.dart';

@JsonSerializable()
class CategoryDto {
  const CategoryDto({required this.id, required this.name, required this.slug, this.iconUrl, this.openStoreCount = 0});

  factory CategoryDto.fromJson(Map<String, dynamic> json) => _$CategoryDtoFromJson(json);

  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final int openStoreCount;
}

/// Item de `GET /stores`.
@JsonSerializable()
class StoreSummaryDto {
  const StoreSummaryDto({
    required this.id,
    required this.name,
    required this.categoryIds,
    required this.ratingAvg,
    required this.ratingCount,
    required this.distanceKm,
    required this.etaMinutes,
    required this.estimatedDeliveryFee,
    required this.minOrderAmount,
    required this.isOpenNow,
    required this.deliversToYou,
    this.logoUrl,
    this.coverUrl,
    this.tags = const [],
    this.promoLabel,
    this.nextOpeningAt,
  });

  factory StoreSummaryDto.fromJson(Map<String, dynamic> json) => _$StoreSummaryDtoFromJson(json);

  final String id;
  final String name;
  final String? logoUrl;
  final String? coverUrl;
  final List<String> categoryIds;
  final double ratingAvg;
  final int ratingCount;
  final double distanceKm;
  final int etaMinutes;
  final MoneyDto estimatedDeliveryFee;
  final MoneyDto minOrderAmount;
  final bool isOpenNow;
  final bool deliversToYou;

  /// Momentos del día en los que el negocio destaca (desayuno, almuerzo…).
  @JsonKey(defaultValue: <String>[])
  final List<String> tags;
  final String? promoLabel;

  /// Si está cerrado, la próxima apertura según su horario (ISO 8601). El
  /// backend aún no lo envía: hasta entonces llega `null`.
  final DateTime? nextOpeningAt;
}

/// Respuesta paginada de `GET /stores`.
@JsonSerializable()
class StorePageDto {
  const StorePageDto({required this.items, required this.page, required this.limit, required this.total, this.openCount = 0});

  factory StorePageDto.fromJson(Map<String, dynamic> json) => _$StorePageDtoFromJson(json);

  final List<StoreSummaryDto> items;
  final int page;
  final int limit;
  final int total;
  final int openCount;
}

@JsonSerializable()
class OpeningHoursDto {
  const OpeningHoursDto({required this.dayOfWeek, required this.opensAt, required this.closesAt});

  factory OpeningHoursDto.fromJson(Map<String, dynamic> json) => _$OpeningHoursDtoFromJson(json);

  final int dayOfWeek;
  final int opensAt;
  final int closesAt;
}

/// `GET /stores/:id`: los campos del resumen más el detalle.
@JsonSerializable()
class StoreDetailDto {
  const StoreDetailDto({
    required this.summary,
    required this.addressLine,
    required this.schedules,
    this.description,
    this.phone,
    this.ownerName,
    this.attendingSince,
  });

  factory StoreDetailDto.fromJson(Map<String, dynamic> json) =>
      _$StoreDetailDtoFromJson({...json, 'summary': json});

  final StoreSummaryDto summary;
  final String? description;
  final String addressLine;
  final String? phone;
  final List<OpeningHoursDto> schedules;
  final String? ownerName;
  final int? attendingSince;
}

@JsonSerializable()
class MenuItemDto {
  const MenuItemDto({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.hasChoices,
    this.description,
    this.imageUrl,
    this.isFeatured = false,
  });

  factory MenuItemDto.fromJson(Map<String, dynamic> json) => _$MenuItemDtoFromJson(json);

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final MoneyDto price;
  final bool isAvailable;
  final bool hasChoices;
  @JsonKey(defaultValue: false)
  final bool isFeatured;
}

@JsonSerializable()
class MenuSectionDto {
  const MenuSectionDto({required this.id, required this.name, required this.products});

  factory MenuSectionDto.fromJson(Map<String, dynamic> json) => _$MenuSectionDtoFromJson(json);

  final String id;
  final String name;
  final List<MenuItemDto> products;
}

/// `GET /stores/:id/products`: menú agrupado por secciones.
@JsonSerializable()
class StoreMenuDto {
  const StoreMenuDto({required this.sections});

  factory StoreMenuDto.fromJson(Map<String, dynamic> json) => _$StoreMenuDtoFromJson(json);

  final List<MenuSectionDto> sections;
}
