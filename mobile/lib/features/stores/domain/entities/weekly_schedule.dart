import 'package:chaski/core/utils/formatters.dart';
import 'package:equatable/equatable.dart';

/// Horario de un día. Minutos desde medianoche en hora local de la ciudad;
/// si `closesAt < opensAt`, el turno cruza la medianoche.
final class OpeningHours extends Equatable {
  const OpeningHours({required this.dayOfWeek, required this.opensAt, required this.closesAt});

  /// 0 = domingo … 6 = sábado (igual que el backend).
  final int dayOfWeek;
  final int opensAt;
  final int closesAt;

  bool get crossesMidnight => closesAt < opensAt;

  @override
  List<Object?> get props => [dayOfWeek, opensAt, closesAt];
}

final class WeeklySchedule extends Equatable {
  const WeeklySchedule(this.hours);

  final List<OpeningHours> hours;

  /// Horarios del día de la semana de [date] (Dart: lunes = 1 … domingo = 7).
  List<OpeningHours> hoursOn(DateTime date) {
    final day = date.weekday % 7;
    return hours.where((h) => h.dayOfWeek == day).toList();
  }

  bool isClosedAllDay(int dayOfWeek) => hours.every((h) => h.dayOfWeek != dayOfWeek);

  /// Próxima apertura a partir de [now]: `(díasDesdeHoy, minutosDesdeMedianoche)`,
  /// o `null` si no abre en la próxima semana.
  ({int inDays, int opensAt})? nextOpening(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    for (var offset = 0; offset <= 7; offset++) {
      final day = (now.weekday + offset) % 7;
      final candidates = hours.where((h) => h.dayOfWeek == day && (offset > 0 || h.opensAt > minutes)).toList()
        ..sort((a, b) => a.opensAt.compareTo(b.opensAt));
      if (candidates.isNotEmpty) return (inDays: offset, opensAt: candidates.first.opensAt);
    }
    return null;
  }

  /// Fecha y hora de la próxima apertura (para programar un pedido), o `null`
  /// si no abre en la próxima semana.
  DateTime? nextOpeningAt(DateTime now) {
    final next = nextOpening(now);
    if (next == null) return null;
    return DateTime(now.year, now.month, now.day + next.inDays, next.opensAt ~/ 60, next.opensAt % 60);
  }

  /// Minuto del día en que cierra el turno en curso, o `null` si ahora está
  /// cerrado. Cuenta el turno de ayer que cruzó la medianoche.
  int? closesAt(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    final today = now.weekday % 7;
    final yesterday = (today + 6) % 7;
    for (final h in hours) {
      final inToday = h.dayOfWeek == today &&
          (h.crossesMidnight ? minutes >= h.opensAt : minutes >= h.opensAt && minutes < h.closesAt);
      final fromYesterday = h.dayOfWeek == yesterday && h.crossesMidnight && minutes < h.closesAt;
      if (inToday || fromYesterday) return h.closesAt;
    }
    return null;
  }

  bool isOpenAt(DateTime now) => closesAt(now) != null;

  @override
  List<Object?> get props => [hours];
}

/// Textos del horario. Una sola forma de decir cuándo abre o cierra un
/// negocio, en 12 h: "hoy a las 6:00 pm".
extension WeeklyScheduleLabels on WeeklySchedule {
  /// Cuándo abre, dentro de una frase: "hoy a las 6:00 pm" · "el sábado a las
  /// 9:00 am". `null` si no abre en la semana.
  String? opensPhrase(DateTime now) => opensPhraseFor(nextOpeningAt(now), now: now);

  /// "Abre hoy a las 6:00 pm" · "Abre mañana a las 7:00 am".
  String? nextOpeningLabel(DateTime now) => switch (opensPhrase(now)) {
    final phrase? => 'Abre $phrase',
    null => null,
  };

  /// "Cierra 10:00 pm" si ahora está dentro de un turno; `null` si no.
  String? closingLabel(DateTime now) => switch (closesAt(now)) {
    final minutes? => 'Cierra ${Formatters.timeOfDay(minutes)}',
    null => null,
  };
}

/// La frase de apertura a partir de la fecha ya calculada (p. ej.
/// `StoreSummary.nextOpeningAt`): "hoy a las 6:00 pm". `null` si [at] es `null`.
String? opensPhraseFor(DateTime? at, {DateTime? now}) => at == null ? null : Formatters.whenPhrase(at, now: now);
