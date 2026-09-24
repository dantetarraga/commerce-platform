import 'package:chaski/core/domain/validated.dart';
import 'package:chaski/core/domain/value_failure.dart';
import 'package:equatable/equatable.dart';

final class GeoCoordinates extends Equatable {
  const GeoCoordinates._(this.latitude, this.longitude);

  /// Para valores que ya vienen validados (constantes, backend).
  factory GeoCoordinates.trusted(double latitude, double longitude) =>
      switch (create(latitude, longitude)) {
        Valid(:final value) => value,
        Invalid(:final failure) => throw ArgumentError(failure),
      };

  final double latitude;
  final double longitude;

  static Validated<GeoCoordinates> create(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) return const Invalid(OutOfRange(-90, 90));
    if (longitude < -180 || longitude > 180) return const Invalid(OutOfRange(-180, 180));
    return Valid(GeoCoordinates._(latitude, longitude));
  }

  @override
  List<Object?> get props => [latitude, longitude];
}
