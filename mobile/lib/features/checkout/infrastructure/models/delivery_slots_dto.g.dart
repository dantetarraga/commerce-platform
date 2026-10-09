// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_slots_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliverySlotsDto _$DeliverySlotsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeliverySlotsDto', json, ($checkedConvert) {
      final val = DeliverySlotsDto(
        days: $checkedConvert(
          'days',
          (v) => (v as List<dynamic>)
              .map((e) => DeliveryDayDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

DeliveryDayDto _$DeliveryDayDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeliveryDayDto', json, ($checkedConvert) {
      final val = DeliveryDayDto(
        date: $checkedConvert('date', (v) => v as String),
        slots: $checkedConvert(
          'slots',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });
