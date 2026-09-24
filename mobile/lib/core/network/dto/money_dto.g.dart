// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoneyDto _$MoneyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MoneyDto', json, ($checkedConvert) {
      final val = MoneyDto(
        amount: $checkedConvert('amount', (v) => (v as num).toInt()),
        currency: $checkedConvert('currency', (v) => v as String),
      );
      return val;
    });
