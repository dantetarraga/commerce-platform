import 'package:chaski/core/domain/money.dart';

/// Formatos propios del checkout (hora en 12 h, días cortos, montos escritos).
abstract final class CheckoutFormat {
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  /// "6:30" (sin sufijo, para la grilla de horas).
  static String hour12(DateTime at) {
    final h = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '$h:${at.minute.toString().padLeft(2, '0')}';
  }

  /// "am" / "pm".
  static String meridiem(DateTime at) => at.hour < 12 ? 'am' : 'pm';

  /// "6:30 pm".
  static String clock(DateTime at) => '${hour12(at)} ${meridiem(at)}';

  static DateTime dateOnly(DateTime at) => DateTime(at.year, at.month, at.day);

  /// "Hoy" · "Mañana" · "Jue 25".
  static String day(DateTime at, DateTime now) {
    final diff = dateOnly(at).difference(dateOnly(now)).inDays;
    return switch (diff) {
      0 => 'Hoy',
      1 => 'Mañana',
      _ => '${_weekdays[at.weekday - 1]} ${at.day}',
    };
  }

  /// "hoy a las 6:30 pm" · "mañana a las 7:00 am" · "el jue 25 a las 8:00 pm".
  static String whenPhrase(DateTime at, DateTime now) {
    final d = day(at, now);
    final prefix = switch (d) {
      'Hoy' => 'hoy',
      'Mañana' => 'mañana',
      _ => 'el ${d.toLowerCase()}',
    };
    return '$prefix a las ${clock(at)}';
  }

  /// "20–30 min" a partir de la estimación del negocio.
  static String eta(int minutes) => '${minutes - 5}–${minutes + 5} min';

  /// Convierte lo que escribe la persona ("4", "4.5", "4,50") a céntimos.
  static Money? parseSoles(String text) {
    final clean = text.trim().replaceAll('S/', '').replaceAll(' ', '').replaceAll(',', '.');
    if (clean.isEmpty) return null;
    final value = double.tryParse(clean);
    if (value == null || value < 0) return null;
    return Money((value * 100).round());
  }
}
