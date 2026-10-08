import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/stores/domain/entities/store_detail.dart';
import 'package:apamuy/features/stores/domain/entities/store_menu.dart';
import 'package:apamuy/features/stores/domain/entities/store_summary.dart';
import 'package:apamuy/shared/design_system/design_system.dart';

/// Argumentos opcionales al abrir un negocio: la portada ya conocida (se
/// muestra al instante) y el tag del elemento compartido.
class StoreRouteArgs {
  const StoreRouteArgs({this.coverUrl, this.heroTag});

  final String? coverUrl;
  final Object? heroTag;
}

/// Tag del elemento compartido portada-card → portada-detalle.
String storeCoverHeroTag(String storeId, String source) => 'store-cover-$source-$storeId';

/// Por qué no se puede pedir ahora a [store] (cerrado o fuera de zona).
String cannotOrderMessage(StoreSummary store) =>
    store.isOpenNow ? '${store.name} no llega a tu dirección' : '${store.name} está cerrado ahora';

extension StoreSummaryCard on StoreSummary {
  StoreCardData toCardData({bool withDistance = false, String? closedLabel}) => StoreCardData(
    id: id,
    name: name,
    coverUrl: coverUrl,
    logoUrl: logoUrl,
    etaMinutes: etaMinutes,
    deliveryFee: deliveryFee,
    isOpen: isOpenNow,
    distanceKm: withDistance ? distanceKm : null,
    rating: rating.hasReviews ? rating.average : null,
    promo: promoLabel,
    closedLabel: closedLabel,
    minOrder: minOrderAmount,
  );

  /// "Abre mañana a las 7:00 am", o `null` si está abierto o no se sabe.
  String? opensLabel(DateTime now) => switch (opensPhrase(now)) {
    final phrase? => 'Abre $phrase',
    null => null,
  };

  CartStore toCartStore() => CartStore(
    id: id,
    name: name,
    logoUrl: logoUrl,
    deliveryFee: deliveryFee,
    minOrderAmount: minOrderAmount,
    etaMinutes: etaMinutes,
  );
}

extension MenuItemCard on MenuItem {
  ProductCardData toCardData() => ProductCardData(
    id: id,
    name: name,
    description: description,
    imageUrl: imageUrl,
    price: price,
    isAvailable: isAvailable,
    fromPrice: hasChoices,
  );
}

extension StoreDetailLabels on StoreDetail {
  /// "Atiende Rosa desde 2009".
  String? get attendedByLabel => switch ((ownerName, attendingSince)) {
    (final owner?, final since?) => 'Atiende $owner desde $since',
    (final owner?, null) => 'Atiende $owner',
    _ => null,
  };
}
