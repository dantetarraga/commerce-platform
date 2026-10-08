import 'package:chaski/features/stores/domain/entities/category.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_page.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:chaski/features/stores/domain/entities/weekly_schedule.dart';
import 'package:chaski/features/stores/infrastructure/models/store_dtos.dart';

extension CategoryDtoMapper on CategoryDto {
  Category toDomain() => Category(id: id, name: name, slug: slug, iconUrl: iconUrl, openStoreCount: openStoreCount);
}

extension StoreSummaryDtoMapper on StoreSummaryDto {
  StoreSummary toDomain() => StoreSummary(
    id: id,
    name: name,
    logoUrl: logoUrl,
    coverUrl: coverUrl,
    categoryIds: categoryIds,
    rating: StoreRating(average: ratingAvg, count: ratingCount),
    distanceKm: distanceKm,
    etaMinutes: etaMinutes,
    deliveryFee: estimatedDeliveryFee.toDomain(),
    minOrderAmount: minOrderAmount.toDomain(),
    isOpenNow: isOpenNow,
    deliversToYou: deliversToYou,
    tags: tags,
    promoLabel: promoLabel,
    nextOpeningAt: nextOpeningAt?.toLocal(),
  );
}

extension StorePageDtoMapper on StorePageDto {
  StorePage toDomain() => StorePage(
    items: items.map((dto) => dto.toDomain()).toList(),
    page: page,
    limit: limit,
    total: total,
    openCount: openCount,
  );
}

extension StoreDetailDtoMapper on StoreDetailDto {
  StoreDetail toDomain() => StoreDetail(
    summary: summary.toDomain(),
    description: description,
    addressLine: addressLine,
    phone: phone,
    ownerName: ownerName,
    attendingSince: attendingSince,
    schedule: WeeklySchedule([
      for (final h in schedules)
        OpeningHours(dayOfWeek: h.dayOfWeek, opensAt: h.opensAt, closesAt: h.closesAt),
    ]),
  );
}

extension MenuItemDtoMapper on MenuItemDto {
  MenuItem toDomain() => MenuItem(
    id: id,
    name: name,
    description: description,
    imageUrl: imageUrl,
    price: price.toDomain(),
    isAvailable: isAvailable,
    hasChoices: hasChoices,
    isFeatured: isFeatured,
  );
}

extension StoreMenuDtoMapper on StoreMenuDto {
  StoreMenu toDomain() => StoreMenu([
    for (final section in sections)
      MenuSection(
        id: section.id,
        name: section.name,
        items: [
          for (final item in section.products)
            MenuItem(
              id: item.id,
              name: item.name,
              description: item.description,
              imageUrl: item.imageUrl,
              price: item.price.toDomain(),
              isAvailable: item.isAvailable,
              hasChoices: item.hasChoices,
              isFeatured: item.isFeatured,
            ),
        ],
      ),
  ]);
}
