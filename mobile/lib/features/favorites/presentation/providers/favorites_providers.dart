import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/features/favorites/domain/favorites.dart';
import 'package:chaski/features/favorites/infrastructure/local_favorites_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => LocalFavoritesRepository(ref.watch(localJsonStoreProvider)),
);

/// Favoritos del usuario. El cambio se ve al instante y se guarda detrás.
final favoritesProvider = AsyncNotifierProvider<FavoritesController, Favorites>(FavoritesController.new);

class FavoritesController extends AsyncNotifier<Favorites> {
  @override
  Future<Favorites> build() => ref.watch(favoritesRepositoryProvider).load();

  /// Agrega o quita. Devuelve si quedó como favorito.
  Future<bool> toggle(FavoriteKind kind, String id) async {
    final current = state.value ?? await future;
    final next = current.toggle(kind, id);
    state = AsyncData(next);
    await ref.read(favoritesRepositoryProvider).save(next);
    return next.contains(kind, id);
  }
}

/// ¿Este negocio está en favoritos? (falso mientras carga).
final ProviderFamily<bool, String> isFavoriteStoreProvider = Provider.family<bool, String>(
  (ref, storeId) => ref.watch(favoritesProvider).value?.contains(FavoriteKind.store, storeId) ?? false,
);

/// ¿Este producto está en favoritos? (falso mientras carga).
final ProviderFamily<bool, String> isFavoriteProductProvider = Provider.family<bool, String>(
  (ref, productId) => ref.watch(favoritesProvider).value?.contains(FavoriteKind.product, productId) ?? false,
);
