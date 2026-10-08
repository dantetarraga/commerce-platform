import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/auth/auth.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/infrastructure/datasources/fake_orders_remote_data_source.dart';
import 'package:apamuy/features/orders/infrastructure/datasources/fake_staff_orders.dart';
import 'package:apamuy/features/orders/infrastructure/datasources/orders_remote_data_source.dart';
import 'package:apamuy/features/orders/infrastructure/orders_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orders_providers.g.dart';

@Riverpod(keepAlive: true)
OrdersRemoteDataSource ordersRemoteDataSource(Ref ref) {
  if (!ref.watch(appEnvProvider).useFakeData) {
    return ApiOrdersRemoteDataSource(ref.watch(apiClientProvider), realtime: ref.watch(realtimeClientProvider));
  }
  final fake = FakeOrdersRemoteDataSource(ref.watch(fakeBackendProvider));
  ref.onDispose(fake.dispose);
  return fake;
}

/// Pedidos fake de Apamuy Socios, compartidos por los modos Negocio y
/// Repartidor. Entra un pedido nuevo cada 7 pasos de la demo.
@Riverpod(keepAlive: true)
FakeStaffOrders fakeStaffOrders(Ref ref) {
  final backend = ref.watch(fakeBackendProvider);
  final fake = FakeStaffOrders(backend, newOrderEvery: backend.orderStep * 7);
  ref.onDispose(fake.dispose);
  return fake;
}

@Riverpod(keepAlive: true)
OrdersRepository ordersRepository(Ref ref) => OrdersRepositoryImpl(ref.watch(ordersRemoteDataSourceProvider));

/// Historial (más reciente primero).
@riverpod
Future<OrderLists> ordersHistory(Ref ref) =>
    ref.watch(ordersRepositoryProvider).history().then((r) => r.getOrThrow());

/// Conteos, lo ahorrado y "Volver a pedir". Se vuelve a pedir cada vez que se
/// refresca el historial (al pedir, calificar, cancelar o tirar para recargar).
@riverpod
Future<OrdersSummary> ordersSummary(Ref ref) async {
  await ref.watch(ordersHistoryProvider.future);
  return (await ref.read(ordersRepositoryProvider).summary()).getOrThrow();
}

/// Estado vivo de un pedido.
@riverpod
Stream<Order> orderWatch(Ref ref, String orderId) => ref.watch(ordersRepositoryProvider).watch(orderId);

/// Id del pedido en curso (el que muestra la barra de compra). Al abrir la app se
/// recupera del historial; al confirmar un pedido se fija aquí.
@Riverpod(keepAlive: true)
class ActiveOrderId extends _$ActiveOrderId {
  @override
  Future<String?> build() async {
    final history = await ref.watch(ordersRepositoryProvider).history();
    return switch (history) {
      Ok(:final value) => value.active.firstOrNull?.id,
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
