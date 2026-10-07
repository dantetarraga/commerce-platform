import 'package:equatable/equatable.dart';

/// Dinero en unidades mínimas (céntimos). Nunca `double`.
final class Money extends Equatable implements Comparable<Money> {
  const Money(this.cents, {this.currency = defaultCurrency})
    : assert(cents >= 0, 'Money no admite montos negativos');

  const Money.zero({this.currency = defaultCurrency}) : cents = 0;

  static const defaultCurrency = 'PEN';

  /// Lo que escribe la persona ("4", "4.5", "4,50", "S/ 12") en soles a
  /// céntimos. `null` si está vacío, no es un número o es negativo.
  static Money? tryParse(String text, {String currency = defaultCurrency}) {
    final clean = text.trim().replaceAll('S/', '').replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    if (clean.isEmpty) return null;
    final value = double.tryParse(clean);
    if (value == null || !value.isFinite || value < 0) return null;
    return Money((value * 100).round(), currency: currency);
  }

  final int cents;
  final String currency;

  bool get isZero => cents == 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(cents + other.cents, currency: currency);
  }

  /// Resta. El resultado no puede ser negativo: compara antes con [<] si
  /// [other] puede ser mayor.
  Money operator -(Money other) {
    _assertSameCurrency(other);
    if (other.cents > cents) throw ArgumentError('El resultado sería negativo: $this - $other');
    return Money(cents - other.cents, currency: currency);
  }

  Money operator *(int factor) => Money(cents * factor, currency: currency);

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return cents.compareTo(other.cents);
  }

  bool operator <(Money other) => compareTo(other) < 0;

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('No se pueden operar $currency y ${other.currency}');
    }
  }

  @override
  List<Object?> get props => [cents, currency];

  @override
  String toString() => 'Money($cents $currency)';
}
