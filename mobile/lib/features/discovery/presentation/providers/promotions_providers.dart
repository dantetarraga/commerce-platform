import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/features/discovery/domain/promotion.dart';
import 'package:apamuy/features/discovery/infrastructure/datasources/promotions_remote_data_source.dart';
import 'package:apamuy/features/discovery/infrastructure/repositories/discovery_repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'promotions_providers.g.dart';

@Riverpod(keepAlive: true)
PromotionsRepository promotionsRepository(Ref ref) => PromotionsRepositoryImpl(
  ref.watch(appEnvProvider).useFakeData
      ? FakePromotionsRemoteDataSource(ref.watch(fakeBackendProvider))
      : ApiPromotionsRemoteDataSource(ref.watch(apiClientProvider)),
);

@riverpod
Future<List<Promotion>> promotions(Ref ref) =>
    ref.watch(promotionsRepositoryProvider).getActivePromotions().then((r) => r.getOrThrow());
