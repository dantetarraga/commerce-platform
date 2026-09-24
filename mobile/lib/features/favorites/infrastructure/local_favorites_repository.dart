import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/features/favorites/domain/favorites.dart';

/// Favoritos guardados en el dispositivo como `{stores: [...], products: [...]}`.
class LocalFavoritesRepository implements FavoritesRepository {
  LocalFavoritesRepository(this._store);

  static const _key = 'chaski.favorites';

  final LocalJsonStore _store;

  @override
  Future<Favorites> load() async {
    final raw = await _store.read(_key);
    if (raw is! Map) return Favorites.empty;
    Set<String> ids(Object? list) => list is List ? {...list.whereType<String>()} : const {};
    return Favorites(storeIds: ids(raw['stores']), productIds: ids(raw['products']));
  }

  @override
  Future<void> save(Favorites favorites) => _store.write(_key, {
    'stores': favorites.storeIds.toList(),
    'products': favorites.productIds.toList(),
  });
}
