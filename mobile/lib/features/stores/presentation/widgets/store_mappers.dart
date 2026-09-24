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

const _weekdays = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];

String? nextOpeningLabelFor(WeeklySchedule schedule, DateTime now) {
  final next = schedule.nextOpening(now);
  if (next == null) return null;
  final time = Formatters.timeOfDay(next.opensAt);
  return switch (next.inDays) {
    0 => 'Abre hoy a las $time',
    1 => 'Abre mañana a las $time',
    _ => 'Abre el ${_weekdays[(now.weekday + next.inDays) % 7]} a las $time',
  };
}

/// Fecha y hora de la próxima apertura (para programar un pedido), o null.
DateTime? nextOpeningAt(WeeklySchedule schedule, DateTime now) {
  final next = schedule.nextOpening(now);
  if (next == null) return null;
  return DateTime(now.year, now.month, now.day + next.inDays, next.opensAt ~/ 60, next.opensAt % 60);
}

/// "Cierra 16:00" si ahora está dentro de un turno; null si no.
String? closingLabelFor(WeeklySchedule schedule, DateTime now) {
  final minutes = now.hour * 60 + now.minute;
  final today = now.weekday % 7;
  final yesterday = (today + 6) % 7;
  for (final h in schedule.hours) {
    final inToday = h.dayOfWeek == today &&
        (h.crossesMidnight ? minutes >= h.opensAt : minutes >= h.opensAt && minutes < h.closesAt);
    // Turno de ayer que cruzó la medianoche y sigue abierto.
    final fromYesterday = h.dayOfWeek == yesterday && h.crossesMidnight && minutes < h.closesAt;
    if (inToday || fromYesterday) return 'Cierra ${Formatters.timeOfDay(h.closesAt)}';
  }
  return null;
}

/// "hoy a las 18:30" · "mañana a las 07:00" · "el sábado a las 09:00".
String scheduledAtLabel(DateTime at, DateTime now) {
  final days = DateTime(at.year, at.month, at.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  final time = Formatters.clock(at);
  return switch (days) {
    <= 0 => 'hoy a las $time',
    1 => 'mañana a las $time',
    _ => 'el ${_weekdays[at.weekday % 7]} a las $time',
  };
}
