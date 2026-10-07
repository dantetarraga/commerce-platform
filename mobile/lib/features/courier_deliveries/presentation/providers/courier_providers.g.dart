// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courier_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(courierRemoteDataSource)
final courierRemoteDataSourceProvider = CourierRemoteDataSourceProvider._();

final class CourierRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          CourierRemoteDataSource,
          CourierRemoteDataSource,
          CourierRemoteDataSource
        >
    with $Provider<CourierRemoteDataSource> {
  CourierRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courierRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courierRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<CourierRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CourierRemoteDataSource create(Ref ref) {
    return courierRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourierRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourierRemoteDataSource>(value),
    );
  }
}

String _$courierRemoteDataSourceHash() =>
    r'70fc6080458ca857250a16b6f8c14d6856e68b6c';

@ProviderFor(courierRepository)
final courierRepositoryProvider = CourierRepositoryProvider._();

final class CourierRepositoryProvider
    extends
        $FunctionalProvider<
          CourierRepository,
          CourierRepository,
          CourierRepository
        >
    with $Provider<CourierRepository> {
  CourierRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courierRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courierRepositoryHash();

  @$internal
  @override
  $ProviderElement<CourierRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CourierRepository create(Ref ref) {
    return courierRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourierRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourierRepository>(value),
    );
  }
}

String _$courierRepositoryHash() => r'989dd325ecea1e0936246468aecef4483effa81b';

/// El repartidor y su disponibilidad.

@ProviderFor(CourierMe)
final courierMeProvider = CourierMeProvider._();

/// El repartidor y su disponibilidad.
final class CourierMeProvider
    extends $AsyncNotifierProvider<CourierMe, CourierProfile> {
  /// El repartidor y su disponibilidad.
  CourierMeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courierMeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courierMeHash();

  @$internal
  @override
  CourierMe create() => CourierMe();
}

String _$courierMeHash() => r'34cb52c3bd6be03e465e8451352b4e2c401cad6e';

/// El repartidor y su disponibilidad.

abstract class _$CourierMe extends $AsyncNotifier<CourierProfile> {
  FutureOr<CourierProfile> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CourierProfile>, CourierProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CourierProfile>, CourierProfile>,
              AsyncValue<CourierProfile>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Pedidos listos para tomar. Solo se consultan (cada [courierPollEvery], con
/// la app a la vista) si está conectado y libre.

@ProviderFor(courierAvailableOrders)
final courierAvailableOrdersProvider = CourierAvailableOrdersProvider._();

/// Pedidos listos para tomar. Solo se consultan (cada [courierPollEvery], con
/// la app a la vista) si está conectado y libre.

final class CourierAvailableOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffOrder>>,
          List<StaffOrder>,
          FutureOr<List<StaffOrder>>
        >
    with $FutureModifier<List<StaffOrder>>, $FutureProvider<List<StaffOrder>> {
  /// Pedidos listos para tomar. Solo se consultan (cada [courierPollEvery], con
  /// la app a la vista) si está conectado y libre.
  CourierAvailableOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courierAvailableOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courierAvailableOrdersHash();

  @$internal
  @override
  $FutureProviderElement<List<StaffOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StaffOrder>> create(Ref ref) {
    return courierAvailableOrders(ref);
  }
}

String _$courierAvailableOrdersHash() =>
    r'615b3895ce209a8c147ccccb1273b2ebc1199535';

/// El pedido que está llevando (o null). Conectado, se revisa cada
/// [courierPollEvery] por si lo cancelan o cambia.

@ProviderFor(courierActiveDelivery)
final courierActiveDeliveryProvider = CourierActiveDeliveryProvider._();

/// El pedido que está llevando (o null). Conectado, se revisa cada
/// [courierPollEvery] por si lo cancelan o cambia.

final class CourierActiveDeliveryProvider
    extends
        $FunctionalProvider<
          AsyncValue<StaffOrder?>,
          StaffOrder?,
          FutureOr<StaffOrder?>
        >
    with $FutureModifier<StaffOrder?>, $FutureProvider<StaffOrder?> {
  /// El pedido que está llevando (o null). Conectado, se revisa cada
  /// [courierPollEvery] por si lo cancelan o cambia.
  CourierActiveDeliveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courierActiveDeliveryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courierActiveDeliveryHash();

  @$internal
  @override
  $FutureProviderElement<StaffOrder?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StaffOrder?> create(Ref ref) {
    return courierActiveDelivery(ref);
  }
}

String _$courierActiveDeliveryHash() =>
    r'1cd9aedab7d395bfa1b7db0803a7983eed3b07ef';

@ProviderFor(courierSummary)
final courierSummaryProvider = CourierSummaryProvider._();

final class CourierSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CourierSummary>,
          CourierSummary,
          FutureOr<CourierSummary>
        >
    with $FutureModifier<CourierSummary>, $FutureProvider<CourierSummary> {
  CourierSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courierSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courierSummaryHash();

  @$internal
  @override
  $FutureProviderElement<CourierSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CourierSummary> create(Ref ref) {
    return courierSummary(ref);
  }
}

String _$courierSummaryHash() => r'59f76cb9bf3c519d630724e521618f6d5615e9ac';

/// Tomar, recoger y entregar. Al terminar refresca todo lo del repartidor.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.

@ProviderFor(CourierActions)
final courierActionsProvider = CourierActionsProvider._();

/// Tomar, recoger y entregar. Al terminar refresca todo lo del repartidor.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
final class CourierActionsProvider
    extends $NotifierProvider<CourierActions, void> {
  /// Tomar, recoger y entregar. Al terminar refresca todo lo del repartidor.
  // keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
  CourierActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courierActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courierActionsHash();

  @$internal
  @override
  CourierActions create() => CourierActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$courierActionsHash() => r'28d25c65aff85f1b8493026b1dac610cce01f7b5';

/// Tomar, recoger y entregar. Al terminar refresca todo lo del repartidor.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.

abstract class _$CourierActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
