import 'package:apamuy/features/checkout/domain/delivery_slots.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delivery_slots_dto.g.dart';

@JsonSerializable()
class DeliverySlotsDto {
  const DeliverySlotsDto({required this.days});

  factory DeliverySlotsDto.fromJson(Map<String, dynamic> json) => _$DeliverySlotsDtoFromJson(json);

  final List<DeliveryDayDto> days;

  /// Las horas llegan en UTC; la app las muestra en la hora del teléfono.
  List<DeliveryDay> toEntities() => [
    for (final day in days)
      DeliveryDay(
        date: DateTime.parse(day.date),
        slots: [for (final at in day.slots) DateTime.parse(at).toLocal()],
      ),
  ];
}

@JsonSerializable()
class DeliveryDayDto {
  const DeliveryDayDto({required this.date, required this.slots});

  factory DeliveryDayDto.fromJson(Map<String, dynamic> json) => _$DeliveryDayDtoFromJson(json);

  /// `YYYY-MM-DD`.
  final String date;
  final List<String> slots;
}
