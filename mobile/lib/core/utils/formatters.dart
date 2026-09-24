import 'package:chaski/core/domain/money.dart';
import 'package:intl/intl.dart';

/// En Perú el uso común es "S/ 1,250.50": símbolo adelante, coma de miles y
/// punto decimal. La locale es_PE de CLDR usa coma decimal y pone el símbolo
/// al final, así que el patrón se fija explícitamente.
abstract final class Formatters {
  static final _amount = NumberFormat('#,##0.00', 'en_US');
  static final _oneDecimal = NumberFormat('0.0', 'en_US');

  static String money(Money money) {
    final value = money.cents / 100;
    return money.currency == 'PEN'
        ? 'S/ ${_amount.format(value)}'
        : NumberFormat.simpleCurrency(name: money.currency).format(value);
  }

  static String distance(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${_oneDecimal.format(km)} km';

  static String rating(double value) => _oneDecimal.format(value);

  static String eta(int minutes) => '${minutes - 5}-${minutes + 5} min';

  /// Minutos desde medianoche → "11:30".
  static String timeOfDay(int minutes) {
    final normalized = minutes % (24 * 60);
    final h = (normalized ~/ 60).toString().padLeft(2, '0');
    final m = (normalized % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// "7:02" (hora local de un momento).
  static String clock(DateTime at) => timeOfDay(at.hour * 60 + at.minute);

  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  /// "Hoy, 7:02" · "Ayer, 20:15" · "Hace 3 días" · "12 sep".
  static String relativeDay(DateTime at, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = DateTime(today.year, today.month, today.day).difference(DateTime(at.year, at.month, at.day)).inDays;
    return switch (days) {
      0 => 'Hoy, ${clock(at)}',
      1 => 'Ayer, ${clock(at)}',
      < 7 && > 1 => 'Hace $days días',
      _ => '${at.day} ${_months[at.month - 1]}',
    };
  }
}
