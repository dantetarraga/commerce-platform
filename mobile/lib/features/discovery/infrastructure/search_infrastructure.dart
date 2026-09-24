import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/fake/fake_catalog_json.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/network/dto/money_dto.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/utils/text_utils.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_infrastructure.g.dart';

@JsonSerializable()
class StoreHitDto {
  const StoreHitDto({
    required this.id,
    required this.name,
    required this.ratingAvg,
    required this.etaMinutes,
    required this.isOpenNow,
    this.logoUrl,
  });

  factory StoreHitDto.fromJson(Map<String, dynamic> json) => _$StoreHitDtoFromJson(json);

  final String id;
  final String name;
  final String? logoUrl;
  final double ratingAvg;
  final int etaMinutes;
  final bool isOpenNow;
}

@JsonSerializable()
class ProductHitDto {
  const ProductHitDto({
    required this.id,
    required this.name,
    required this.price,
    required this.storeId,
    required this.storeName,
    this.imageUrl,
    this.hasChoices = false,
  });

  factory ProductHitDto.fromJson(Map<String, dynamic> json) => _$ProductHitDtoFromJson(json);

  final String id;
  final String name;
  final String? imageUrl;
  final MoneyDto price;
  final String storeId;
  final String storeName;
  @JsonKey(defaultValue: false)
  final bool hasChoices;

  ProductHit toDomain() => ProductHit(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: price.toDomain(),
    storeId: storeId,
    storeName: storeName,
    hasChoices: hasChoices,
  );
}

/// `GET /search?q=&lat=&lng=`.
@JsonSerializable()
class SearchResponseDto {
  const SearchResponseDto({required this.stores, required this.products});

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) => _$SearchResponseDtoFromJson(json);

  final List<StoreHitDto> stores;
  final List<ProductHitDto> products;

  SearchResults toDomain() => SearchResults(
    stores: [
      for (final s in stores)
        StoreHit(
          id: s.id,
          name: s.name,
          logoUrl: s.logoUrl,
          ratingAvg: s.ratingAvg,
          etaMinutes: s.etaMinutes,
          isOpenNow: s.isOpenNow,
        ),
    ],
    products: [for (final p in products) p.toDomain()],
  );
}

abstract interface class SearchRemoteDataSource {
  Future<SearchResponseDto> search(String query, GeoCoordinates location);
}

class ApiSearchRemoteDataSource implements SearchRemoteDataSource {
  const ApiSearchRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<SearchResponseDto> search(String query, GeoCoordinates location) async {
    final data = await _api.get(
      '/search',
      query: {'q': query, 'lat': location.latitude, 'lng': location.longitude},
    );
    return SearchResponseDto.fromJson(data as Map<String, dynamic>);
  }
}

/// Búsqueda sin tildes sobre el catálogo de prueba (imita unaccent + pg_trgm).
class FakeSearchRemoteDataSource implements SearchRemoteDataSource {
  const FakeSearchRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<SearchResponseDto> search(String query, GeoCoordinates location) async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    final needle = normalizeForSearch(query);
    bool matches(Object? text) => text is String && normalizeForSearch(text).contains(needle);

    final stores = _backend.listOf(catalog, 'stores');
    final products = _backend.listOf(catalog, 'products');
    return SearchResponseDto.fromJson({
      'stores': [
        for (final s in stores)
          if (matches(s['name']) || matches(s['description'])) _backend.storeSummaryJson(s),
      ],
      'products': [
        for (final p in products)
          if (p['isAvailable'] == true && (matches(p['name']) || matches(p['description'])))
            {
              ..._backend.menuItemJson(p),
              'storeId': p['storeId'],
              'storeName': _backend.findById(stores, p['storeId'] as String)?['name'],
            },
      ],
    });
  }
}

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<Result<SearchResults>> search(String query, GeoCoordinates location) =>
      guard(() async => (await _remote.search(query, location)).toDomain());
}
