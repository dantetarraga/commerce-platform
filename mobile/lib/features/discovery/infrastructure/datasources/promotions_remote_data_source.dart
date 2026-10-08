import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/features/discovery/infrastructure/models/promotion_dto.dart';

abstract interface class PromotionsRemoteDataSource {
  Future<List<PromotionDto>> getPromotions();
}

class ApiPromotionsRemoteDataSource implements PromotionsRemoteDataSource {
  const ApiPromotionsRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<PromotionDto>> getPromotions() async {
    final data = await _api.get('/promotions') as List<dynamic>;
    return data.map((e) => PromotionDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class FakePromotionsRemoteDataSource implements PromotionsRemoteDataSource {
  const FakePromotionsRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<PromotionDto>> getPromotions() async {
    await _backend.delay();
    final catalog = await _backend.catalog();
    return _backend.listOf(catalog, 'promotions').map(PromotionDto.fromJson).toList();
  }
}
