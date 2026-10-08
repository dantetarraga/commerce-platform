import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/features/stores/domain/entities/store_filter.dart';
import 'package:apamuy/features/stores/domain/entities/store_query.dart';
import 'package:apamuy/features/stores/domain/entities/store_summary.dart';
import 'package:apamuy/features/stores/infrastructure/datasources/remote/fake_stores_remote_data_source.dart';
import 'package:apamuy/features/stores/infrastructure/datasources/remote/stores_remote_data_source.dart';
import 'package:apamuy/features/stores/presentation/providers/stores_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

StoreSummary _store(String id, {bool open = true, int fee = 300, double rating = 4.0, int reviews = 10, String? promo, DateTime? opens}) => StoreSummary(
  id: id,
  name: id,
  categoryIds: const [],
  rating: StoreRating(average: rating, count: reviews),
  distanceKm: 1,
  etaMinutes: 25,
  deliveryFee: Money(fee),
  minOrderAmount: const Money.zero(),
  isOpenNow: open,
  deliversToYou: true,
  promoLabel: promo,
  nextOpeningAt: opens,
);

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('los filtros viajan al backend con su nombre de la API', () {
    expect(StoreFilter.values.map((f) => f.apiName), ['open_now', 'free_delivery', 'top_rated', 'no_minimum', 'offers']);
    expect(StoreFilter.quick, [StoreFilter.openNow, StoreFilter.freeDelivery, StoreFilter.topRated]);
  });

  test('los mismos filtros son el mismo provider, aunque el Set sea otro', () {
    final picked = [StoreFilter.openNow, StoreFilter.offers];
    expect(StoreFilters({...picked}), StoreFilters({...picked.reversed}));
    expect(storesProvider(filters: StoreFilters({...picked})), storesProvider(filters: StoreFilters({...picked})));
  });

  test('la consulta manda filtros y "abiertos primero" al backend', () async {
    final api = _MockApiClient();
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {'items': <Object?>[], 'page': 1, 'limit': 20, 'total': 0, 'openCount': 0},
    );
    await ApiStoresRemoteDataSource(api).getStores(
      StoreQuery(location: GeoCoordinates.trusted(-14.79, -71.41), filters: const {StoreFilter.openNow, StoreFilter.topRated}),
    );
    final query = verify(() => api.get('/stores', query: captureAny(named: 'query'))).captured.single as Map<String, Object?>;
    expect(query['filters'], 'open_now,top_rated');
    expect(query['openFirst'], isTrue);
  });

  test('orden con etiqueta para la hoja y para la frase', () {
    expect(StoreSort.rating.label, 'Mejor calificados');
    expect(StoreSort.distance.inlineLabel, 'cercanía');
  });

  test('un cerrado dice cuándo abre con la fecha del resumen', () {
    final now = DateTime(2026, 9, 22, 22);
    expect(_store('a', open: false, opens: DateTime(2026, 9, 23, 7)).closedLabel(now), 'Cerrado · abre mañana a las 7:00 am');
    expect(_store('a', open: false).closedLabel(now), 'Cerrado');
    expect(_store('a', opens: DateTime(2026, 9, 23, 7)).opensPhrase(now), isNull);
  });

  test('la búsqueda en la carta la resuelve el datasource, sin tildes ni repetidos', () async {
    final source = FakeStoresRemoteDataSource(FakeBackend(latency: Duration.zero));
    final all = await source.searchMenu('st_chaski_dorado', '');
    expect(all.map((i) => i.id).toSet(), hasLength(all.length));
    final pollos = await source.searchMenu('st_chaski_dorado', 'POLLO');
    expect(pollos, isNotEmpty);
    expect(pollos.every((i) => '${i.name} ${i.description ?? ''}'.toLowerCase().contains('pollo')), isTrue);
    expect(await source.searchMenu('st_chaski_dorado', 'nada-que-ver'), isEmpty);
  });
}
