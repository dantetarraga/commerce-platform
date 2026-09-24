import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:chaski/features/stores/domain/entities/weekly_schedule.dart';
import 'package:equatable/equatable.dart';

final class StoreDetail extends Equatable {
  const StoreDetail({
    required this.summary,
    required this.addressLine,
    required this.schedule,
    this.description,
    this.phone,
    this.ownerName,
    this.attendingSince,
  });

  final StoreSummary summary;
  final String? description;
  final String addressLine;
  final String? phone;
  final WeeklySchedule schedule;

  /// Quién atiende ("Rosa") y desde qué año: la confianza local tiene nombre.
  final String? ownerName;
  final int? attendingSince;

  String get id => summary.id;
  String get name => summary.name;

  @override
  List<Object?> get props => [summary, description, addressLine, phone, schedule, ownerName, attendingSince];
}
