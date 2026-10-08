import 'package:apamuy/core/config/city.dart';
import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delivery_location.g.dart';

/// Ubicación a la que el usuario quiere que le lleguen los pedidos.
final class DeliveryLocation extends Equatable {
  const DeliveryLocation({required this.label, required this.coordinates});

  final String label;
  final GeoCoordinates coordinates;

  @override
  List<Object?> get props => [label, coordinates];
}

/// La dirección seleccionada en `addresses`; sin ella, el GPS y si no, la plaza.
@Riverpod(keepAlive: true)
class CurrentDeliveryLocation extends _$CurrentDeliveryLocation {
  @override
  DeliveryLocation build() => DeliveryLocation(label: 'Espinar, Cusco', coordinates: cityCenter);

  void change(DeliveryLocation location) => state = location;

  /// Usa el GPS solo si ya hay permiso (no muestra el diálogo) y cae en la zona.
  Future<void> useGpsIfAllowed() async {
    final reading = await ref.read(locationServiceProvider).current(ask: false);
    if (state.coordinates != cityCenter) return;
    if (reading case LocationFix(:final coordinates) when isInCoverage(coordinates)) {
      state = DeliveryLocation(label: 'Tu ubicación', coordinates: coordinates);
    }
  }
}
