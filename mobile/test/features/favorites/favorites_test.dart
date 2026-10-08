import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/storage/local_json_store.dart';
import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:apamuy/features/favorites/domain/favorites.dart';
import 'package:apamuy/features/favorites/favorites.dart';
import 'package:apamuy/features/favorites/infrastructure/local_favorites_repository.dart';
import 'package:apamuy/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavorites extends Mock implements FavoritesRepository {}

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
      await store.write('apamuy.favorites', 'basura');
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
    expect(saved.getOrThrow(), isTrue);
    expect(container.read(isFavoriteStoreProvider('st_1')), isTrue);
    expect((await LocalFavoritesRepository(store).load()).storeIds, {'st_1'});

    await container.read(favoritesProvider.notifier).toggle(FavoriteKind.store, 'st_1');
    expect(container.read(isFavoriteStoreProvider('st_1')), isFalse);
  });

  test('si no se puede guardar, vuelve atrás y devuelve el error', () async {
    final repository = _MockFavorites();
    registerFallbackValue(Favorites.empty);
    when(repository.load).thenAnswer((_) async => Favorites.empty);
    when(() => repository.save(any())).thenThrow(Exception('disco lleno'));
    final container = ProviderContainer(overrides: [favoritesRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    await container.read(favoritesProvider.future);

    final result = await container.read(favoritesProvider.notifier).toggle(FavoriteKind.store, 'st_1');

    expect(result, isA<Err<bool>>());
    expect(container.read(isFavoriteStoreProvider('st_1')), isFalse);
  });
}
