import 'package:chaski/app/config/app_config_provider.dart';
import 'package:chaski/core/fake/fake_providers.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/infrastructure/datasources/fake_orders_remote_data_source.dart';
import 'package:chaski/features/orders/infrastructure/datasources/orders_remote_data_source.dart';
import 'package:chaski/features/orders/infrastructure/orders_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orders_providers.g.dart';

@Riverpod(keepAlive: true)
OrdersRemoteDataSource ordersRemoteDataSource(Ref ref) {
  if (!ref.watch(appEnvProvider).useFakeData) return ApiOrdersRemoteDataSource(ref.watch(apiClientProvider));
  final fake = FakeOrdersRemoteDataSource(ref.watch(fakeBackendProvider));
  ref.onDispose(fake.dispose);
  return fake;
}

@Riverpod(keepAlive: true)
OrdersRepository ordersRepository(Ref ref) => OrdersRepositoryImpl(ref.watch(ordersRemoteDataSourceProvider));

/// Historial (más reciente primero).
@riverpod
Future<List<Order>> ordersHistory(Ref ref) =>
    ref.watch(ordersRepositoryProvider).history().then((r) => r.getOrThrow());

/// Estado vivo de un pedido.
@riverpod
Stream<Order> orderWatch(Ref ref, String orderId) => ref.watch(ordersRepositoryProvider).watch(orderId);

/// Id del pedido en curso (el que muestra la posta). Al abrir la app se
/// recupera del historial; al confirmar un pedido se fija aquí.
@Riverpod(keepAlive: true)
class ActiveOrderId extends _$ActiveOrderId {
  @override
  Future<String?> build() async {
    final history = await ref.watch(ordersRepositoryProvider).history();
    return switch (history) {
      Ok(:final value) => value.where((o) => o.isActive).firstOrNull?.id,
      Err() => null,
    };
  }

  void set(String orderId) => state = AsyncData(orderId);

  void clear() => state = const AsyncData(null);
}

/// El pedido en curso con su estado vivo (o `null`).
@Riverpod(keepAlive: true)
Stream<Order?> activeOrder(Ref ref) async* {
  final id = await ref.watch(activeOrderIdProvider.future);
  if (id == null) {
    yield null;
    return;
  }
  yield* ref.watch(ordersRepositoryProvider).watch(id);
}

/// Negocios de pedidos anteriores, sin repetir (para "Volver a pedir").
@riverpod
Future<List<Order>> recentOrdersByStore(Ref ref) async {
  final history = await ref.watch(ordersHistoryProvider.future);
  final seen = <String>{};
  return [
    for (final order in history)
      if (order.status == OrderStatus.delivered && seen.add(order.store.id)) order,
  ].take(8).toList();
}
