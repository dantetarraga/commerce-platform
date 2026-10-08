import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/result/result.dart';
import 'package:equatable/equatable.dart';

final class StoreHit extends Equatable {
  const StoreHit({
    required this.id,
    required this.name,
    required this.ratingAvg,
    required this.etaMinutes,
    required this.isOpenNow,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final double ratingAvg;
  final int etaMinutes;
  final bool isOpenNow;

  @override
  List<Object?> get props => [id, name, logoUrl, ratingAvg, etaMinutes, isOpenNow];
}

final class ProductHit extends Equatable {
  const ProductHit({
    required this.id,
    required this.name,
    required this.price,
    required this.storeId,
    required this.storeName,
    this.imageUrl,
    this.hasChoices = false,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final Money price;
  final String storeId;
  final String storeName;

  /// Tiene variantes u opciones: se abre el detalle en vez del "+" rápido.
  final bool hasChoices;

  @override
  List<Object?> get props => [id, name, imageUrl, price, storeId, storeName, hasChoices];
}

final class SearchResults extends Equatable {
  const SearchResults({required this.stores, required this.products});

  static const empty = SearchResults(stores: [], products: []);

  final List<StoreHit> stores;
  final List<ProductHit> products;

  bool get isEmpty => stores.isEmpty && products.isEmpty;

  @override
  List<Object?> get props => [stores, products];
}

abstract interface class SearchRepository {
  /// Con [openOnly], solo negocios abiertos ahora (lo filtra el backend).
  Future<Result<SearchResults>> search(String query, GeoCoordinates location, {bool openOnly = false});
}

class SearchCatalog {
  const SearchCatalog(this._repository);

  static const minQueryLength = 2;

  final SearchRepository _repository;

  /// No consulta al backend con textos demasiado cortos.
  Future<Result<SearchResults>> call(String rawQuery, GeoCoordinates location, {bool openOnly = false}) async {
    final query = rawQuery.trim();
    if (query.length < minQueryLength) return const Result.ok(SearchResults.empty);
    return _repository.search(query, location, openOnly: openOnly);
  }
}

/// "Lo más pedido en Espinar": un término y en cuántos negocios se encuentra.
final class PopularSearch extends Equatable {
  const PopularSearch({required this.term, required this.storeCount});

  final String term;
  final int storeCount;

  @override
  List<Object?> get props => [term, storeCount];
}

/// "Hecho en Espinar": productos de la ciudad.
abstract interface class LocalProductsRepository {
  Future<Result<List<ProductHit>>> localProducts();
}

abstract interface class PopularSearchesRepository {
  Future<Result<List<PopularSearch>>> popular();
}
