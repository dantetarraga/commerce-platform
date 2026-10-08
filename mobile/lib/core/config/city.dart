import 'package:chaski/core/domain/geo_coordinates.dart';

/// Ciudad donde opera Apamuy (Yauri, capital de la provincia de Espinar).
const cityName = 'Yauri';

/// Plaza de Yauri: punto de partida cuando no hay dirección ni GPS.
final cityCenter = GeoCoordinates.trusted(-14.7936, -71.4128);

/// Radio de reparto alrededor de [cityCenter].
const cityCoverageKm = 6.0;

bool isInCoverage(GeoCoordinates point) => point.distanceKmTo(cityCenter) <= cityCoverageKm;
