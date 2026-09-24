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
    for (var offset = 0; offset < 7; offset++) {
      final day = (now.weekday + offset) % 7;
      final candidates = hours.where((h) => h.dayOfWeek == day && (offset > 0 || h.opensAt > minutes)).toList()
        ..sort((a, b) => a.opensAt.compareTo(b.opensAt));
      if (candidates.isNotEmpty) return (inDays: offset, opensAt: candidates.first.opensAt);
    }
    return null;
  }

  @override
  List<Object?> get props => [hours];
}
