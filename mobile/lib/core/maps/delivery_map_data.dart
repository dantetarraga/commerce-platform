/// Coordenada geográfica real, independiente del SDK del mapa.
class MapCoordinate {
  const MapCoordinate(this.latitude, this.longitude)
    : assert(latitude >= -90 && latitude <= 90, 'Latitud fuera de rango'),
      assert(longitude >= -180 && longitude <= 180, 'Longitud fuera de rango');

  final double latitude;
  final double longitude;
}

/// Datos que un adaptador de Google Maps, Mapbox u OSM puede representar.
/// Sin coordenadas la vista es ilustrativa: [estimatedProgress] no es GPS.
class DeliveryMapData {
  const DeliveryMapData({
    required this.estimatedProgress,
    this.showCourier = false,
    this.storeLabel = 'Negocio',
    this.destinationLabel = 'Tu puerta',
    this.store,
    this.courier,
    this.destination,
    this.route = const [],
  });

  final double estimatedProgress;
  final bool showCourier;
  final String storeLabel;
  final String destinationLabel;
  final MapCoordinate? store;
  final MapCoordinate? courier;
  final MapCoordinate? destination;
  final List<MapCoordinate> route;
}
