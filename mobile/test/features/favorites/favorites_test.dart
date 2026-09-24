import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/favorites/infrastructure/local_favorites_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Favorites', () {
    test('toggle agrega primero y quita', () {
      final f = Favorites.empty.toggle(FavoriteKind.store, 'a').toggle(FavoriteKind.store, 'b');
      expect(f.storeIds.toList(), ['b', 'a']);
      expect(f.productIds, isEmpty);
      expect(f.toggle(FavoriteKind.store, 'a').storeIds, {'b'});
    });

    test('negocios y productos no se mezclan', () {
      final f = Favorites.empty.toggle(FavoriteKind.product, 'x');
      expect(f.contains(FavoriteKind.product, 'x'), isTrue);
      expect(f.contains(FavoriteKind.store, 'x'), isFalse);
    });
  });

  group('LocalFavoritesRepository', () {
    test('guarda y vuelve a leer', () async {
      final store = MemoryJsonStore();
      const favorites = Favorites(storeIds: {'st_1'}, productIds: {'pr_1', 'pr_2'});
      await LocalFavoritesRepository(store).save(favorites);
      expect(await LocalFavoritesRepository(store).load(), favorites);
    });

    test('sin datos o con datos raros devuelve vacío', () async {
      final store = MemoryJsonStore();
      expect(await LocalFavoritesRepository(store).load(), Favorites.empty);
      await store.write('chaski.favorites', 'basura');
      expect(await LocalFavoritesRepository(store).load(), Favorites.empty);
    });
  });

  test('el controller cambia al instante y persiste', () async {
    final store = MemoryJsonStore();
    final container = ProviderContainer(overrides: [localJsonStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await container.read(favoritesProvider.future);
    expect(container.read(isFavoriteStoreProvider('st_1')), isFalse);

    final saved = await container.read(favoritesProvider.notifier).toggle(FavoriteKind.store, 'st_1');
    expect(saved, isTrue);
    expect(container.read(isFavoriteStoreProvider('st_1')), isTrue);
    expect((await LocalFavoritesRepository(store).load()).storeIds, {'st_1'});

    await container.read(favoritesProvider.notifier).toggle(FavoriteKind.store, 'st_1');
    expect(container.read(isFavoriteStoreProvider('st_1')), isFalse);
  });
}
