import 'package:chaski/core/domain/geo_coordinates.dart';
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

/// Fase 1: centro de Espinar. En la Fase 2 lo reemplaza la dirección
/// seleccionada en el feature `addresses` (o la ubicación del GPS).
@Riverpod(keepAlive: true)
class CurrentDeliveryLocation extends _$CurrentDeliveryLocation {
  @override
  DeliveryLocation build() => DeliveryLocation(
    label: 'Espinar, Cusco',
    coordinates: GeoCoordinates.trusted(-14.7936, -71.4128),
  );

  void change(DeliveryLocation location) => state = location;
}
