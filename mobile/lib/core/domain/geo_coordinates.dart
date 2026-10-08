import 'dart:math' as math;

import 'package:apamuy/core/domain/validated.dart';
import 'package:apamuy/core/domain/value_failure.dart';
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

  /// Distancia en línea recta (haversine), igual que la calcula el backend.
  double distanceKmTo(GeoCoordinates other) {
    const earthRadiusKm = 6371.0;
    double rad(double degrees) => degrees * math.pi / 180;
    final dLat = rad(other.latitude - latitude);
    final dLng = rad(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitude)) * math.cos(rad(other.latitude)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(a));
  }

  @override
  List<Object?> get props => [latitude, longitude];
}
