import 'package:chaski/core/errors/failure_mapper.dart';
import 'package:chaski/core/fake/fake_backend.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/discovery/domain/promotion.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotions_infrastructure.g.dart';

@JsonSerializable()
class PromotionDto {
  const PromotionDto({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.storeId,
    this.couponCode,
  });

  factory PromotionDto.fromJson(Map<String, dynamic> json) => _$PromotionDtoFromJson(json);

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? storeId;
  final String? couponCode;

  Promotion toDomain() => Promotion(
    id: id,
    title: title,
    subtitle: subtitle,
    imageUrl: imageUrl,
    storeId: storeId,
    couponCode: couponCode,
  );
}

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

class PromotionsRepositoryImpl implements PromotionsRepository {
  const PromotionsRepositoryImpl(this._remote);

  final PromotionsRemoteDataSource _remote;

  @override
  Future<Result<List<Promotion>>> getActivePromotions() =>
      guard(() async => (await _remote.getPromotions()).map((dto) => dto.toDomain()).toList());
}
