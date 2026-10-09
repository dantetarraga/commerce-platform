import 'package:apamuy/core/result/result.dart';
import 'package:equatable/equatable.dart';

/// Un día de la hoja "¿Para cuándo?" con las horas que el backend acepta.
final class DeliveryDay extends Equatable {
  const DeliveryDay({required this.date, required this.slots});

  /// Medianoche local del día.
  final DateTime date;

  /// Horas de llegada cada 15 min; vacío si ese día el negocio no atiende.
  final List<DateTime> slots;

  bool get isClosed => slots.isEmpty;

  @override
  List<Object?> get props => [date, slots];
}

/// Las horas las calcula el backend con el horario del negocio y la hora de la
/// ciudad: así una hora ofrecida nunca se rechaza al pedir.
abstract interface class DeliverySlotsRepository {
  Future<Result<List<DeliveryDay>>> forStore(String storeId);
}
