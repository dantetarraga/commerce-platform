import 'package:equatable/equatable.dart';

/// Dinero en unidades mínimas (céntimos). Nunca `double`.
final class Money extends Equatable implements Comparable<Money> {
  const Money(this.cents, {this.currency = defaultCurrency})
    : assert(cents >= 0, 'Money no admite montos negativos');

  const Money.zero({this.currency = defaultCurrency}) : cents = 0;

  static const defaultCurrency = 'PEN';

  final int cents;
  final String currency;

  bool get isZero => cents == 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(cents + other.cents, currency: currency);
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
