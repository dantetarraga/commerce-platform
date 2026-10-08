import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:equatable/equatable.dart';

sealed class PaymentMethod extends Equatable {
  const PaymentMethod();

  String get label;

  @override
  List<Object?> get props => [label];
}

final class YapePayment extends PaymentMethod {
  const YapePayment();

  @override
  String get label => 'Yape';
}

final class PlinPayment extends PaymentMethod {
  const PlinPayment();

  @override
  String get label => 'Plin';
}

/// Efectivo; [changeFor] = con cuánto paga (para llevar el vuelto).
final class CashPayment extends PaymentMethod {
  const CashPayment({this.changeFor});

  final Money? changeFor;

  @override
  String get label => 'Efectivo';

  @override
  List<Object?> get props => [label, changeFor];
}

final class CardPayment extends PaymentMethod {
  const CardPayment();

  @override
  String get label => 'Tarjeta al recibir';
}

extension PaymentMethodCollect on PaymentMethod {
  /// Cómo cobra el socio: "Efectivo · paga con S/ 50.00" si el cliente
  /// avisó con cuánto paga; si no, solo el medio ("Yape").
  String get collectLabel => switch (this) {
    CashPayment(:final changeFor?) => '$label · paga con ${Formatters.money(changeFor)}',
    _ => label,
  };
}
