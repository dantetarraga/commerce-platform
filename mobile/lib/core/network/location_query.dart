import 'package:chaski/core/domain/geo_coordinates.dart';

/// `?lat=&lng=` para los endpoints que calculan delivery según la ubicación.
Map<String, Object?>? locationQuery(GeoCoordinates? near) =>
    near == null ? null : {'lat': near.latitude, 'lng': near.longitude};
