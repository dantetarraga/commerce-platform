import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/config/city.dart';
import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'city_area.g.dart';

/// Zona de reparto: un círculo alrededor del centro de la ciudad. La edita el admin
/// en Ciudades y el backend la usa para aceptar direcciones y pedidos.
final class CityArea extends Equatable {
  const CityArea({required this.center, required this.coverageKm});

  /// Hasta tener la de `GET /cities` (o sin red la primera vez).
  static final fallback = CityArea(center: cityCenter, coverageKm: 6);

  final GeoCoordinates center;
  final double coverageKm;

  bool contains(GeoCoordinates point) =>
      point.distanceKmTo(center) <= coverageKm;

  /// Una ciudad de `GET /cities` o lo guardado en el teléfono; `null` si no sirve.
  static CityArea? fromJson(Object? json) {
    if (json is! Map) return null;
    final (lat, lng, km) = (
      json['centerLat'],
      json['centerLng'],
      json['coverageKm'],
    );
    if (lat is! num || lng is! num || km is! num || km <= 0) return null;
    final center = GeoCoordinates.create(
      lat.toDouble(),
      lng.toDouble(),
    ).valueOrNull;
    return center == null
        ? null
        : CityArea(center: center, coverageKm: km.toDouble());
  }

  Map<String, Object> toJson() => {
    'centerLat': center.latitude,
    'centerLng': center.longitude,
    'coverageKm': coverageKm,
  };

  @override
  List<Object?> get props => [center, coverageKm];
}

/// La zona vigente: la guardada al abrir y luego la del backend, que se guarda para
/// la próxima vez. Así un cambio en el panel llega sin publicar otra versión.
@Riverpod(keepAlive: true)
class CurrentCityArea extends _$CurrentCityArea {
  static const _storageKey = 'apamuy.city_area';

  @override
  CityArea build() {
    _refresh().ignore();
    return CityArea.fallback;
  }

  Future<void> _refresh() async {
    final store = ref.read(localJsonStoreProvider);
    if (CityArea.fromJson(await store.read(_storageKey)) case final cached?) {
      state = cached;
    }
    if (ref.read(appEnvProvider).useFakeData) return;
    try {
      final cities = await ref.read(apiClientProvider).get('/cities');
      // Hoy opera una sola ciudad; con varias, se elegirá la de la dirección.
      final area = cities is List && cities.isNotEmpty
          ? CityArea.fromJson(cities.first)
          : null;
      if (area == null) return;
      state = area;
      await store.write(_storageKey, area.toJson());
    } on Object {
      // Sin red: queda la guardada o la de respaldo; el backend valida igual.
    }
  }
}
