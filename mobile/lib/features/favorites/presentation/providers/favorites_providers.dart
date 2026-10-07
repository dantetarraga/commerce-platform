import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:chaski/features/favorites/domain/favorites.dart';
import 'package:chaski/features/favorites/infrastructure/local_favorites_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorites_providers.g.dart';

@Riverpod(keepAlive: true)
FavoritesRepository favoritesRepository(Ref ref) => LocalFavoritesRepository(ref.watch(localJsonStoreProvider));

/// Favoritos del usuario. El cambio se ve al instante y se guarda detrás.
@Riverpod(keepAlive: true, name: 'favoritesProvider')
class FavoritesController extends _$FavoritesController {
  @override
  Future<Favorites> build() => ref.watch(favoritesRepositoryProvider).load();

  /// Agrega o quita; `Ok(true)` si quedó como favorito. Si no se pudo guardar,
  /// vuelve al estado anterior y devuelve el error.
  Future<Result<bool>> toggle(FavoriteKind kind, String id) async {
    final current = state.value ?? await future;
    final next = current.toggle(kind, id);
    state = AsyncData(next);
    try {
      await ref.read(favoritesRepositoryProvider).save(next);
      return Result.ok(next.contains(kind, id));
    } on Object {
      state = AsyncData(current);
      return const Result.err(ServerFailure('No pudimos guardar tu favorito. Inténtalo de nuevo.'));
    }
  }
}

/// ¿Este negocio está en favoritos? (falso mientras carga).
@riverpod
bool isFavoriteStore(Ref ref, String storeId) =>
    ref.watch(favoritesProvider.select((f) => f.value?.contains(FavoriteKind.store, storeId) ?? false));

/// ¿Este producto está en favoritos? (falso mientras carga).
@riverpod
bool isFavoriteProduct(Ref ref, String productId) =>
    ref.watch(favoritesProvider.select((f) => f.value?.contains(FavoriteKind.product, productId) ?? false));
