// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ordersRemoteDataSource)
final ordersRemoteDataSourceProvider = OrdersRemoteDataSourceProvider._();

final class OrdersRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          OrdersRemoteDataSource,
          OrdersRemoteDataSource,
          OrdersRemoteDataSource
        >
    with $Provider<OrdersRemoteDataSource> {
  OrdersRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<OrdersRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OrdersRemoteDataSource create(Ref ref) {
    return ordersRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrdersRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrdersRemoteDataSource>(value),
    );
  }
}

String _$ordersRemoteDataSourceHash() =>
    r'725c172e875b2c598f299e4e37864234dd2dfa46';

/// Pedidos fake de Apamuy Socios, compartidos por los modos Negocio y
/// Repartidor. Entra un pedido nuevo cada 7 pasos de la demo.

@ProviderFor(fakeStaffOrders)
final fakeStaffOrdersProvider = FakeStaffOrdersProvider._();

/// Pedidos fake de Apamuy Socios, compartidos por los modos Negocio y
/// Repartidor. Entra un pedido nuevo cada 7 pasos de la demo.

final class FakeStaffOrdersProvider
    extends
        $FunctionalProvider<FakeStaffOrders, FakeStaffOrders, FakeStaffOrders>
    with $Provider<FakeStaffOrders> {
  /// Pedidos fake de Apamuy Socios, compartidos por los modos Negocio y
  /// Repartidor. Entra un pedido nuevo cada 7 pasos de la demo.
  FakeStaffOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fakeStaffOrdersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fakeStaffOrdersHash();

  @$internal
  @override
  $ProviderElement<FakeStaffOrders> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FakeStaffOrders create(Ref ref) {
    return fakeStaffOrders(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FakeStaffOrders value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FakeStaffOrders>(value),
    );
  }
}

String _$fakeStaffOrdersHash() => r'75ded5de8f638ec7650685a6af901fd659db7bee';

@ProviderFor(ordersRepository)
final ordersRepositoryProvider = OrdersRepositoryProvider._();

final class OrdersRepositoryProvider
    extends
        $FunctionalProvider<
          OrdersRepository,
          OrdersRepository,
          OrdersRepository
        >
    with $Provider<OrdersRepository> {
  OrdersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersRepositoryHash();

  @$internal
  @override
  $ProviderElement<OrdersRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrdersRepository create(Ref ref) {
    return ordersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrdersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrdersRepository>(value),
    );
  }
}

String _$ordersRepositoryHash() => r'1c715ff0d3433b7275a56e5ae04e6dc17f6bcd25';

/// Historial (más reciente primero).

@ProviderFor(ordersHistory)
final ordersHistoryProvider = OrdersHistoryProvider._();

/// Historial (más reciente primero).

final class OrdersHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Order>>,
          List<Order>,
          FutureOr<List<Order>>
        >
    with $FutureModifier<List<Order>>, $FutureProvider<List<Order>> {
  /// Historial (más reciente primero).
  OrdersHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<Order>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Order>> create(Ref ref) {
    return ordersHistory(ref);
  }
}

String _$ordersHistoryHash() => r'c578af09a3c9eef2fcbeea1585d6cf7aebfdfc9e';

/// Estado vivo de un pedido.

@ProviderFor(orderWatch)
final orderWatchProvider = OrderWatchFamily._();

/// Estado vivo de un pedido.

final class OrderWatchProvider
    extends $FunctionalProvider<AsyncValue<Order>, Order, Stream<Order>>
    with $FutureModifier<Order>, $StreamProvider<Order> {
  /// Estado vivo de un pedido.
  OrderWatchProvider._({
    required OrderWatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderWatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderWatchHash();

  @override
  String toString() {
    return r'orderWatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Order> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Order> create(Ref ref) {
    final argument = this.argument as String;
    return orderWatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderWatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderWatchHash() => r'11c9a017795b3f3c0a3e078f0e3754a59914d166';

/// Estado vivo de un pedido.

final class OrderWatchFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Order>, String> {
  OrderWatchFamily._()
    : super(
        retry: null,
        name: r'orderWatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Estado vivo de un pedido.

  OrderWatchProvider call(String orderId) =>
      OrderWatchProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderWatchProvider';
}

/// Id del pedido en curso (el que muestra la barra de compra). Al abrir la app se
/// recupera del historial; al confirmar un pedido se fija aquí.

@ProviderFor(ActiveOrderId)
final activeOrderIdProvider = ActiveOrderIdProvider._();

/// Id del pedido en curso (el que muestra la barra de compra). Al abrir la app se
/// recupera del historial; al confirmar un pedido se fija aquí.
final class ActiveOrderIdProvider
    extends $AsyncNotifierProvider<ActiveOrderId, String?> {
  /// Id del pedido en curso (el que muestra la barra de compra). Al abrir la app se
  /// recupera del historial; al confirmar un pedido se fija aquí.
  ActiveOrderIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeOrderIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeOrderIdHash();

  @$internal
  @override
  ActiveOrderId create() => ActiveOrderId();
}

String _$activeOrderIdHash() => r'82c597b9b8d7abc38b0ff1ecf42056c44156a862';

/// Id del pedido en curso (el que muestra la barra de compra). Al abrir la app se
/// recupera del historial; al confirmar un pedido se fija aquí.

abstract class _$ActiveOrderId extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// El pedido en curso con su estado vivo (o `null`).

@ProviderFor(activeOrder)
final activeOrderProvider = ActiveOrderProvider._();

/// El pedido en curso con su estado vivo (o `null`).

final class ActiveOrderProvider
    extends $FunctionalProvider<AsyncValue<Order?>, Order?, Stream<Order?>>
    with $FutureModifier<Order?>, $StreamProvider<Order?> {
  /// El pedido en curso con su estado vivo (o `null`).
  ActiveOrderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeOrderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeOrderHash();

  @$internal
  @override
  $StreamProviderElement<Order?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Order?> create(Ref ref) {
    return activeOrder(ref);
  }
}

String _$activeOrderHash() => r'ca153e9c21483509cf0526e0c603170bd9315351';

/// Negocios de pedidos anteriores, sin repetir (para "Volver a pedir").

@ProviderFor(recentOrdersByStore)
final recentOrdersByStoreProvider = RecentOrdersByStoreProvider._();

/// Negocios de pedidos anteriores, sin repetir (para "Volver a pedir").

final class RecentOrdersByStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Order>>,
          List<Order>,
          FutureOr<List<Order>>
        >
    with $FutureModifier<List<Order>>, $FutureProvider<List<Order>> {
  /// Negocios de pedidos anteriores, sin repetir (para "Volver a pedir").
  RecentOrdersByStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentOrdersByStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentOrdersByStoreHash();

  @$internal
  @override
  $FutureProviderElement<List<Order>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Order>> create(Ref ref) {
    return recentOrdersByStore(ref);
  }
}

String _$recentOrdersByStoreHash() =>
    r'165d324c87eb4e0bc5c4f60f7e3866cff4e7d8bd';
