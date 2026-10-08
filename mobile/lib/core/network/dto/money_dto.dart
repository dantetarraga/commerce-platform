import 'package:apamuy/core/domain/money.dart';
import 'package:json_annotation/json_annotation.dart';

part 'money_dto.g.dart';

/// Formato de dinero de la API: `{ "amount": 1850, "currency": "PEN" }`.
@JsonSerializable()
class MoneyDto {
  const MoneyDto({required this.amount, required this.currency});

  factory MoneyDto.fromJson(Map<String, dynamic> json) => _$MoneyDtoFromJson(json);

  final int amount;
  final String currency;

  Money toDomain() => Money(amount, currency: currency);
}
