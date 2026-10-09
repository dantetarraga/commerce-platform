// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_slots_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deliverySlotsRepository)
final deliverySlotsRepositoryProvider = DeliverySlotsRepositoryProvider._();

final class DeliverySlotsRepositoryProvider
    extends
        $FunctionalProvider<
          DeliverySlotsRepository,
          DeliverySlotsRepository,
          DeliverySlotsRepository
        >
    with $Provider<DeliverySlotsRepository> {
  DeliverySlotsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deliverySlotsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deliverySlotsRepositoryHash();

  @$internal
  @override
  $ProviderElement<DeliverySlotsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeliverySlotsRepository create(Ref ref) {
    return deliverySlotsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeliverySlotsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeliverySlotsRepository>(value),
    );
  }
}

String _$deliverySlotsRepositoryHash() =>
    r'033e5a2318f4e5b424b04fbee87c19366afaff66';

/// Días y horas para programar un pedido a [storeId]; se piden al abrir la hoja.

@ProviderFor(deliverySlots)
final deliverySlotsProvider = DeliverySlotsFamily._();

/// Días y horas para programar un pedido a [storeId]; se piden al abrir la hoja.

final class DeliverySlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DeliveryDay>>,
          List<DeliveryDay>,
          FutureOr<List<DeliveryDay>>
        >
    with
        $FutureModifier<List<DeliveryDay>>,
        $FutureProvider<List<DeliveryDay>> {
  /// Días y horas para programar un pedido a [storeId]; se piden al abrir la hoja.
  DeliverySlotsProvider._({
    required DeliverySlotsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deliverySlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deliverySlotsHash();

  @override
  String toString() {
    return r'deliverySlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DeliveryDay>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DeliveryDay>> create(Ref ref) {
    final argument = this.argument as String;
    return deliverySlots(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeliverySlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deliverySlotsHash() => r'ed500cef837c2d42eed24c3b28eaa88bfe7210c6';

/// Días y horas para programar un pedido a [storeId]; se piden al abrir la hoja.

final class DeliverySlotsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DeliveryDay>>, String> {
  DeliverySlotsFamily._()
    : super(
        retry: null,
        name: r'deliverySlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Días y horas para programar un pedido a [storeId]; se piden al abrir la hoja.

  DeliverySlotsProvider call(String storeId) =>
      DeliverySlotsProvider._(argument: storeId, from: this);

  @override
  String toString() => r'deliverySlotsProvider';
}
