import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/config/city_area.dart';
import 'package:apamuy/core/config/env.dart';
import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/storage/local_json_store.dart';
import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

const _api = AppEnv(apiBaseUrl: 'http://test', useFakeData: false);

Future<CityArea> _settle(ProviderContainer container) async {
  container.read(currentCityAreaProvider);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container.read(currentCityAreaProvider);
}

void main() {
  final plaza = GeoCoordinates.trusted(-14.7936, -71.4128);

  test('la zona contiene lo que está dentro del radio', () {
    final area = CityArea(center: plaza, coverageKm: 6);
    expect(area.contains(plaza), isTrue);
    expect(area.contains(GeoCoordinates.trusted(-14.90, -71.4128)), isFalse); // ~12 km al sur
  });

  test('toma la zona de GET /cities y la guarda para la próxima vez', () async {
    final api = _MockApiClient();
    when(() => api.get('/cities')).thenAnswer(
      (_) async => [
        {'id': 'city_espinar', 'centerLat': -14.7936, 'centerLng': -71.4128, 'coverageKm': 8},
      ],
    );
    final store = MemoryJsonStore();
    final container = ProviderContainer(
      overrides: [
        appEnvProvider.overrideWithValue(_api),
        apiClientProvider.overrideWithValue(api),
        localJsonStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    expect((await _settle(container)).coverageKm, 8);
    expect(CityArea.fromJson(await store.read('apamuy.city_area'))?.coverageKm, 8);
  });

  test('sin red usa la guardada', () async {
    final api = _MockApiClient();
    when(() => api.get('/cities')).thenThrow(Exception('sin red'));
    final store = MemoryJsonStore();
    await store.write('apamuy.city_area', CityArea(center: plaza, coverageKm: 4).toJson());
    final container = ProviderContainer(
      overrides: [
        appEnvProvider.overrideWithValue(_api),
        apiClientProvider.overrideWithValue(api),
        localJsonStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    expect((await _settle(container)).coverageKm, 4);
  });
}
