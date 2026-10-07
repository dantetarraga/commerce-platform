// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_alarm_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orderAlarmController)
final orderAlarmControllerProvider = OrderAlarmControllerProvider._();

final class OrderAlarmControllerProvider
    extends
        $FunctionalProvider<
          OrderAlarmController,
          OrderAlarmController,
          OrderAlarmController
        >
    with $Provider<OrderAlarmController> {
  OrderAlarmControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderAlarmControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderAlarmControllerHash();

  @$internal
  @override
  $ProviderElement<OrderAlarmController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OrderAlarmController create(Ref ref) {
    return orderAlarmController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderAlarmController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderAlarmController>(value),
    );
  }
}

String _$orderAlarmControllerHash() =>
    r'bf44840e6d011605a48b1d485b2c8ab4b70c6e79';
