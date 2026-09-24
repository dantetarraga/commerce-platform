import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/infrastructure/datasources/remote/fake_stores_remote_data_source.dart';
import 'package:chaski/features/stores/infrastructure/repositories/stores_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/result_helpers.dart';

/// Recorre la cadena completa fixture JSON → DTO → mapper → entidad, así un
/// cambio en el catálogo de prueba o en los DTOs rompe aquí y no en la UI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StoresRepositoryImpl repository;
  final espinar = GeoCoordinates.trusted(-14.7936, -71.4128);

  setUp(() {
    repository = StoresRepositoryImpl(FakeStoresRemoteDataSource(FakeBackend(latency: Duration.zero)));
  });

  test('lista negocios ordenados por distancia', () async {
    final result = await repository.getStores(StoreQuery(location: espinar));

    final stores = result.getOrThrow().items;
    expect(stores, isNotEmpty);
    final distances = [for (final s in stores) s.distanceKm];
    expect(distances, [...distances]..sort());
  });

  test('filtra por categoría', () async {
    final result = await repository.getStores(StoreQuery(location: espinar, categoryId: 'cat_postres'));

    final stores = result.getOrThrow().items;
    expect(stores.map((s) => s.name), ['Dulce Kantu']);
  });

  test('arma el menú por secciones con precio "desde" en productos con variantes', () async {
    final result = await repository.getStoreMenu('st_pizzeria_qori');

    final menu = result.getOrThrow();
    final pizzas = menu.sections.firstWhere((s) => s.name == 'Pizzas');
    final andina = pizzas.items.firstWhere((i) => i.id == 'pr_pizza_andina');
    expect(andina.price.cents, 2200); // variante Personal
    expect(andina.hasChoices, isTrue);
  });

  test('un negocio inexistente es NotFoundFailure', () async {
    final result = await repository.getStoreDetail('no-existe');

    expect(failureOf(result), isA<NotFoundFailure>());
  });
}
