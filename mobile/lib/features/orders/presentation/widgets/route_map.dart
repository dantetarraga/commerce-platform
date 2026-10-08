import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/maps/delivery_map_data.dart';
import 'package:apamuy/shared/widgets/delivery_map.dart';
import 'package:flutter/material.dart';

/// Puente del seguimiento al proveedor de mapas intercambiable.
class RouteMap extends StatelessWidget {
  const RouteMap({
    required this.progress,
    this.showCourier = true,
    this.height,
    this.storeLabel = 'Negocio',
    this.destinationLabel = 'Tu puerta',
    this.store,
    this.destination,
    this.courier,
    super.key,
  });

  final double progress;
  final bool showCourier;
  final double? height;
  final String storeLabel;
  final String destinationLabel;

  /// Con negocio y destino se dibuja el mapa real; [courier] es la posición
  /// en vivo del repartidor (null si no se conoce).
  final GeoCoordinates? store;
  final GeoCoordinates? destination;
  final GeoCoordinates? courier;

  static MapCoordinate? _map(GeoCoordinates? at) => at == null ? null : MapCoordinate(at.latitude, at.longitude);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: DeliveryMap(
      data: DeliveryMapData(
        estimatedProgress: progress,
        showCourier: showCourier,
        storeLabel: storeLabel,
        destinationLabel: destinationLabel,
        store: _map(store),
        destination: _map(destination),
        courier: _map(courier),
      ),
    ),
  );
}
