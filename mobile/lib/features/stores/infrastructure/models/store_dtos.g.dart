// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryDto _$CategoryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CategoryDto', json, ($checkedConvert) {
      final val = CategoryDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        iconUrl: $checkedConvert('iconUrl', (v) => v as String?),
        openStoreCount: $checkedConvert(
          'openStoreCount',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
      );
      return val;
    });

StoreSummaryDto _$StoreSummaryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoreSummaryDto', json, ($checkedConvert) {
      final val = StoreSummaryDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        categoryIds: $checkedConvert(
          'categoryIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        ratingAvg: $checkedConvert('ratingAvg', (v) => (v as num).toDouble()),
        ratingCount: $checkedConvert('ratingCount', (v) => (v as num).toInt()),
        distanceKm: $checkedConvert('distanceKm', (v) => (v as num).toDouble()),
        etaMinutes: $checkedConvert('etaMinutes', (v) => (v as num).toInt()),
        estimatedDeliveryFee: $checkedConvert(
          'estimatedDeliveryFee',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        minOrderAmount: $checkedConvert(
          'minOrderAmount',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        isOpenNow: $checkedConvert('isOpenNow', (v) => v as bool),
        deliversToYou: $checkedConvert('deliversToYou', (v) => v as bool),
        logoUrl: $checkedConvert('logoUrl', (v) => v as String?),
        coverUrl: $checkedConvert('coverUrl', (v) => v as String?),
        tags: $checkedConvert(
          'tags',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        ),
        promoLabel: $checkedConvert('promoLabel', (v) => v as String?),
        nextOpeningAt: $checkedConvert(
          'nextOpeningAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    });

StorePageDto _$StorePageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StorePageDto', json, ($checkedConvert) {
      final val = StorePageDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => StoreSummaryDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        limit: $checkedConvert('limit', (v) => (v as num).toInt()),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        openCount: $checkedConvert(
          'openCount',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
      );
      return val;
    });

OpeningHoursDto _$OpeningHoursDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OpeningHoursDto', json, ($checkedConvert) {
      final val = OpeningHoursDto(
        dayOfWeek: $checkedConvert('dayOfWeek', (v) => (v as num).toInt()),
        opensAt: $checkedConvert('opensAt', (v) => (v as num).toInt()),
        closesAt: $checkedConvert('closesAt', (v) => (v as num).toInt()),
      );
      return val;
    });

StoreDetailDto _$StoreDetailDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoreDetailDto', json, ($checkedConvert) {
      final val = StoreDetailDto(
        summary: $checkedConvert(
          'summary',
          (v) => StoreSummaryDto.fromJson(v as Map<String, dynamic>),
        ),
        addressLine: $checkedConvert('addressLine', (v) => v as String),
        schedules: $checkedConvert(
          'schedules',
          (v) => (v as List<dynamic>)
              .map((e) => OpeningHoursDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        description: $checkedConvert('description', (v) => v as String?),
        phone: $checkedConvert('phone', (v) => v as String?),
        ownerName: $checkedConvert('ownerName', (v) => v as String?),
        attendingSince: $checkedConvert(
          'attendingSince',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });

MenuItemDto _$MenuItemDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MenuItemDto', json, ($checkedConvert) {
      final val = MenuItemDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        price: $checkedConvert(
          'price',
          (v) => MoneyDto.fromJson(v as Map<String, dynamic>),
        ),
        isAvailable: $checkedConvert('isAvailable', (v) => v as bool),
        hasChoices: $checkedConvert('hasChoices', (v) => v as bool),
        description: $checkedConvert('description', (v) => v as String?),
        imageUrl: $checkedConvert('imageUrl', (v) => v as String?),
        isFeatured: $checkedConvert('isFeatured', (v) => v as bool? ?? false),
      );
      return val;
    });

MenuSectionDto _$MenuSectionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MenuSectionDto', json, ($checkedConvert) {
      final val = MenuSectionDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        products: $checkedConvert(
          'products',
          (v) => (v as List<dynamic>)
              .map((e) => MenuItemDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

StoreMenuDto _$StoreMenuDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoreMenuDto', json, ($checkedConvert) {
      final val = StoreMenuDto(
        sections: $checkedConvert(
          'sections',
          (v) => (v as List<dynamic>)
              .map((e) => MenuSectionDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });
