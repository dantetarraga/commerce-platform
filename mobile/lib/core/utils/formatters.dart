import 'package:chaski/core/domain/money.dart';
import 'package:intl/intl.dart';

/// Único lugar para los formatos que ve la persona. En Perú se usa "S/ 1,250.50"
/// (la locale es_PE de CLDR no), así que el patrón se fija a mano; horas en 12 h.
abstract final class Formatters {
  static final _amount = NumberFormat('#,##0.00', 'en_US');
  static final _oneDecimal = NumberFormat('0.0', 'en_US');

  /// "S/ 1,250.50".
  static String money(Money money) {
    final value = money.cents / 100;
    return money.currency == 'PEN'
        ? 'S/ ${_amount.format(value)}'
        : NumberFormat.simpleCurrency(name: money.currency).format(value);
  }

  /// "S/ 12" si no hay céntimos; si no, el monto completo ("S/ 12.50").
  static String shortMoney(Money money) {
    final text = Formatters.money(money);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }

  /// Evita que "S/" quede al final de una línea y el monto en la siguiente
  /// (espacio duro tras el símbolo). Úsalo en textos largos que se parten.
  static String keepCurrencyTogether(String text) => text.replaceAll('S/ ', 'S/ ');

  /// Kilómetros → "600 m" · "1.5 km".
  static String distance(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${_oneDecimal.format(km)} km';

  /// Metros → "850 m" · "1.2 km" (mismo formato que [distance]).
  static String meters(int meters) => meters < 1000 ? '$meters m' : distance(meters / 1000);

  static String rating(double value) => _oneDecimal.format(value);

  /// "20–30 min" a partir de la estimación (± 5 min), con raya.
  static String eta(int minutes) => '${minutes - 5}–${minutes + 5} min';

  /// Segundos → "1:05" · "12:00" (cuentas regresivas, reenvío de código).
  static String minutesSeconds(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// Minutos desde medianoche → "11:30 am" · "6:00 pm" (horarios de atención).
  static String timeOfDay(int minutes) {
    final normalized = minutes % (24 * 60);
    return _twelveHour(normalized ~/ 60, normalized % 60);
  }

  /// "6:30 pm": hora local de un momento.
  static String clock(DateTime at) {
    final local = at.toLocal();
    return _twelveHour(local.hour, local.minute);
  }

  /// "6:30" sin sufijo (grillas de horas donde el "am/pm" va aparte).
  static String hour12(DateTime at) {
    final local = at.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$h:${local.minute.toString().padLeft(2, '0')}';
  }

  static String meridiem(DateTime at) => at.toLocal().hour < 12 ? 'am' : 'pm';

  static String _twelveHour(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'am' : 'pm'}';
  }

  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  static const _weekdays = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];

  /// "Hoy, 7:02 am" · "Ayer, 8:15 pm" · "Hace 3 días" · "12 sep".
  static String relativeDay(DateTime at, {DateTime? now}) {
    final local = at.toLocal();
    final days = _daysBetween(now ?? DateTime.now(), local);
    return switch (days) {
      0 => 'Hoy, ${clock(local)}',
      -1 => 'Ayer, ${clock(local)}',
      < -1 && > -7 => 'Hace ${-days} días',
      _ => '${local.day} ${_months[local.month - 1]}',
    };
  }

  /// Cuándo pasará algo, en minúsculas para ir dentro de una frase:
  /// "hoy a las 6:30 pm" · "mañana a las 7:00 am" · "el sábado a las 9:00 am"
  /// (dentro de la semana) · "el 25 sep a las 9:00 am".
  static String whenPhrase(DateTime at, {DateTime? now}) {
    final local = at.toLocal();
    final days = _daysBetween(now ?? DateTime.now(), local);
    final day = switch (days) {
      <= 0 => 'hoy',
      1 => 'mañana',
      < 7 => 'el ${_weekdays[local.weekday % 7]}',
      _ => 'el ${local.day} ${_months[local.month - 1]}',
    };
    return '$day a las ${clock(local)}';
  }

  /// Días de calendario de [from] a [to] (negativo si [to] es anterior).
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime(to.year, to.month, to.day).difference(DateTime(from.year, from.month, from.day)).inDays;
}
