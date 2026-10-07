import 'package:equatable/equatable.dart';

enum FavoriteKind { store, product }

/// Negocios y productos guardados. Solo ids: los datos frescos (precio, si
/// está abierto) se piden al mostrarlos.
final class Favorites extends Equatable {
  const Favorites({this.storeIds = const {}, this.productIds = const {}});

  static const empty = Favorites();

  final Set<String> storeIds;
  final Set<String> productIds;

  Set<String> idsOf(FavoriteKind kind) => switch (kind) {
    FavoriteKind.store => storeIds,
    FavoriteKind.product => productIds,
  };

  bool contains(FavoriteKind kind, String id) => idsOf(kind).contains(id);

  bool get isEmpty => storeIds.isEmpty && productIds.isEmpty;

  /// Agrega o quita [id]. El más reciente queda primero.
  Favorites toggle(FavoriteKind kind, String id) {
    final current = idsOf(kind);
    final next = current.contains(id) ? ({...current}..remove(id)) : {id, ...current};
    return switch (kind) {
      FavoriteKind.store => Favorites(storeIds: next, productIds: productIds),
      FavoriteKind.product => Favorites(storeIds: storeIds, productIds: next),
    };
  }

  @override
  List<Object?> get props => [storeIds, productIds];
}

/// Dónde viven los favoritos (hoy en el dispositivo; mañana, en la cuenta).
abstract interface class FavoritesRepository {
  Future<Favorites> load();

  Future<void> save(Favorites favorites);
}
