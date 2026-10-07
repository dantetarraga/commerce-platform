// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_alarm.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orderAlarm)
final orderAlarmProvider = OrderAlarmProvider._();

final class OrderAlarmProvider
    extends $FunctionalProvider<OrderAlarm, OrderAlarm, OrderAlarm>
    with $Provider<OrderAlarm> {
  OrderAlarmProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderAlarmProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderAlarmHash();

  @$internal
  @override
  $ProviderElement<OrderAlarm> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrderAlarm create(Ref ref) {
    return orderAlarm(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderAlarm value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderAlarm>(value),
    );
  }
}

String _$orderAlarmHash() => r'8b7262fd39b8726e58849526c3109a05eca350a4';
