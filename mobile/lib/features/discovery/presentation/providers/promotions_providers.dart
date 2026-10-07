import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/features/discovery/domain/promotion.dart';
import 'package:chaski/features/discovery/infrastructure/promotions_infrastructure.dart';
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
