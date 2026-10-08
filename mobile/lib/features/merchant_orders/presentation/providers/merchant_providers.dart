import 'dart:async';

import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/network/network_providers.dart';
import 'package:chaski/core/realtime/realtime_client.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/core/utils/text_utils.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/domain/merchant_board.dart';
import 'package:chaski/features/merchant_orders/infrastructure/datasources/merchant_remote_data_source.dart';
import 'package:chaski/features/merchant_orders/infrastructure/merchant_repository_impl.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'merchant_providers.g.dart';

/// Sin WebSocket, cada cuánto se refrescan los pedidos con la app abierta.
const merchantPollEvery = Duration(seconds: 10);

@Riverpod(keepAlive: true)
MerchantRemoteDataSource merchantRemoteDataSource(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeMerchantRemoteDataSource(ref.watch(fakeStaffOrdersProvider))
    : ApiMerchantRemoteDataSource(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
MerchantRepository merchantRepository(Ref ref) => MerchantRepositoryImpl(ref.watch(merchantRemoteDataSourceProvider));

/// Negocios del socio. Pausar o reanudar es optimista.
@riverpod
class MerchantStores extends _$MerchantStores {
  @override
  Future<List<MerchantStore>> build() => ref.watch(merchantRepositoryProvider).stores().then((r) => r.getOrThrow());

  /// Devuelve la falla si no se pudo (y deja el valor anterior).
  Future<Failure?> setAccepting(MerchantStore store, {required bool accepting}) async {
    final previous = state.value;
    if (previous == null) return null;
    state = AsyncData([for (final s in previous) if (s.id == store.id) s.copyWith(isAcceptingOrders: accepting) else s]);
    final result = await ref.read(merchantRepositoryProvider).setAcceptingOrders(store, accepting: accepting);
    if (!ref.mounted) return null;
    return switch (result) {
      Ok() => null,
      Err(:final failure) => () {
        state = AsyncData(previous);
        return failure;
      }(),
    };
  }
}

/// Pedidos en curso. Llegan al instante con `store.orders.changed` (también
/// el pedido nuevo); sin WebSocket, se consultan cada [merchantPollEvery].
@riverpod
Future<List<StaffOrder>> merchantActiveOrders(Ref ref) async {
  refreshLive(ref, events: {RealtimeEvents.storeOrdersChanged}, every: merchantPollEvery, foregroundOnly: false);
  return (await ref.watch(merchantRepositoryProvider).activeOrders()).getOrThrow();
}

/// Los pedidos en curso repartidos en las tres columnas del riel.
@riverpod
AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>> merchantBoard(Ref ref) =>
    ref.watch(merchantActiveOrdersProvider).whenData(MerchantBoardColumn.group);

@riverpod
Future<List<StaffOrder>> merchantTodayOrders(Ref ref) =>
    ref.watch(merchantRepositoryProvider).todayOrders().then((r) => r.getOrThrow());

@riverpod
Future<MerchantSummary> merchantSummary(Ref ref) =>
    ref.watch(merchantRepositoryProvider).summary().then((r) => r.getOrThrow());

/// Acciones sobre un pedido. Al terminar refresca las listas y el resumen.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
@Riverpod(keepAlive: true)
class MerchantOrderActions extends _$MerchantOrderActions {
  @override
  void build() {}

  MerchantRepository get _repo => ref.read(merchantRepositoryProvider);

  Future<Failure?> accept(String orderId, {required int prepMinutes}) =>
      _run(() => _repo.accept(orderId, prepMinutes: prepMinutes));

  Future<Failure?> markReady(String orderId) => _run(() => _repo.markReady(orderId));

  Future<Failure?> reject(String orderId, {required String reason}) => _run(() => _repo.reject(orderId, reason: reason));

  Future<Failure?> _run(Future<Result<StaffOrder>> Function() action) async {
    final result = await action();
    if (!ref.mounted) return null;
    ref
      ..invalidate(merchantActiveOrdersProvider)
      ..invalidate(merchantTodayOrdersProvider)
      ..invalidate(merchantSummaryProvider);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  }
}

/// Productos de un negocio con su interruptor de disponible/agotado.
@riverpod
class MerchantProducts extends _$MerchantProducts {
  @override
  Future<List<MerchantProduct>> build(String storeId) =>
      ref.watch(merchantRepositoryProvider).products(storeId).then((r) => r.getOrThrow());

  Future<Failure?> setAvailable(MerchantProduct product, {required bool available}) async {
    final previous = state.value;
    if (previous == null) return null;
    state = AsyncData([for (final p in previous) if (p.id == product.id) p.copyWith(isAvailable: available) else p]);
    final result = await ref.read(merchantRepositoryProvider).setProductAvailable(product, available: available);
    if (!ref.mounted) return null;
    return switch (result) {
      Ok() => null,
      Err(:final failure) => () {
        state = AsyncData(previous);
        return failure;
      }(),
    };
  }
}

enum ProductFilter { all, available, soldOut }

/// La carta filtrada para la pantalla de productos.
final class MerchantCatalog {
  const MerchantCatalog({required this.total, required this.available, required this.visible});

  final int total;
  final int available;
  int get soldOut => total - available;

  /// Lo que coincide con la búsqueda y el filtro, agrupado por sección.
  final List<MerchantProduct> visible;
}

/// Sección de un producto en la carta ("Otros" si no tiene).
String productSection(MerchantProduct product) => product.section ?? 'Otros';

/// [merchantProductsProvider] buscado (sin importar tildes) y filtrado.
@riverpod
AsyncValue<MerchantCatalog> merchantProductsFiltered(
  Ref ref,
  String storeId, {
  String query = '',
  ProductFilter filter = ProductFilter.all,
}) => ref.watch(merchantProductsProvider(storeId)).whenData((list) {
  final needle = normalizeForSearch(query);
  final visible = [
    for (final p in list)
      if (foldAccents(p.name).contains(needle) &&
          switch (filter) {
            ProductFilter.all => true,
            ProductFilter.available => p.isAvailable,
            ProductFilter.soldOut => !p.isAvailable,
          })
        p,
  ];
  // Por sección y, dentro de cada una, en el orden de la carta.
  final sections = visible.map(productSection).toSet().toList()..sort();
  final grouped = [for (final s in sections) ...visible.where((p) => productSection(p) == s)];
  return MerchantCatalog(total: list.length, available: list.where((p) => p.isAvailable).length, visible: grouped);
});
