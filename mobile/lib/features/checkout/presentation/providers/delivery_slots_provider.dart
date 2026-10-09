import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/features/checkout/domain/delivery_slots.dart';
import 'package:apamuy/features/checkout/infrastructure/delivery_slots_remote_data_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delivery_slots_provider.g.dart';

@riverpod
DeliverySlotsRepository deliverySlotsRepository(Ref ref) => ApiDeliverySlotsRepository(
  ref.watch(appEnvProvider).useFakeData
      ? FakeDeliverySlotsRemoteDataSource(ref.watch(fakeBackendProvider))
      : ApiDeliverySlotsRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Días y horas para programar un pedido a [storeId]; se piden al abrir la hoja.
@riverpod
Future<List<DeliveryDay>> deliverySlots(Ref ref, String storeId) async =>
    (await ref.watch(deliverySlotsRepositoryProvider).forStore(storeId)).getOrThrow();
