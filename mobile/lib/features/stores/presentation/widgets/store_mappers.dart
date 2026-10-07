import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:chaski/features/stores/domain/entities/weekly_schedule.dart';
import 'package:chaski/shared/design_system/design_system.dart';

/// Argumentos opcionales al abrir un negocio: la portada ya conocida (se
/// muestra al instante) y el tag del elemento compartido.
class StoreRouteArgs {
  const StoreRouteArgs({this.coverUrl, this.heroTag});

  final String? coverUrl;
  final Object? heroTag;
}

/// Tag del elemento compartido portada-card → portada-detalle.
String storeCoverHeroTag(String storeId, String source) => 'store-cover-$source-$storeId';

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

  CartStore toCartStore() => CartStore(
    id: id,
    name: name,
    logoUrl: logoUrl,
    deliveryFee: deliveryFee,
    minOrderAmount: minOrderAmount,
    etaMinutes: etaMinutes,
  );
}

extension StoreDetailLabels on StoreDetail {
  /// "Abre hoy a las 18:00" · "Abre mañana 7:00" · "Abre el sábado 9:00".
  String? get nextOpeningLabel => nextOpeningLabelFor(schedule, DateTime.now());

  /// "Atiende Rosa desde 2009".
  String? get attendedByLabel => switch ((ownerName, attendingSince)) {
    (final owner?, final since?) => 'Atiende $owner desde $since',
    (final owner?, null) => 'Atiende $owner',
    _ => null,
  };
}

/// "Abre hoy a las 6:00 pm" · "Abre mañana a las 7:00 am". Delegado a
/// [WeeklyScheduleLabels.nextOpeningLabel].
String? nextOpeningLabelFor(WeeklySchedule schedule, DateTime now) => schedule.nextOpeningLabel(now);

/// Fecha y hora de la próxima apertura (para programar un pedido), o null.
/// Delegado a [WeeklySchedule.nextOpeningAt].
DateTime? nextOpeningAt(WeeklySchedule schedule, DateTime now) => schedule.nextOpeningAt(now);

/// "Cierra 10:00 pm" si ahora está dentro de un turno; null si no. Delegado a
/// [WeeklyScheduleLabels.closingLabel].
String? closingLabelFor(WeeklySchedule schedule, DateTime now) => schedule.closingLabel(now);

/// "hoy a las 6:30 pm" · "mañana a las 7:00 am" · "el sábado a las 9:00 am".
String scheduledAtLabel(DateTime at, DateTime now) => Formatters.whenPhrase(at, now: now);
