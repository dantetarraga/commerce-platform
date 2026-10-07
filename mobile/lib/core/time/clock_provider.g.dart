// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La hora actual, que avanza cada [clockTick]: para contadores que se mueven
/// solos sin polling ni un `Timer` por widget. Se apaga cuando nadie lo mira.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// La hora actual, que avanza cada [clockTick]: para contadores que se mueven
/// solos sin polling ni un `Timer` por widget. Se apaga cuando nadie lo mira.

final class ClockProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// La hora actual, que avanza cada [clockTick]: para contadores que se mueven
  /// solos sin polling ni un `Timer` por widget. Se apaga cuando nadie lo mira.
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return clock(ref);
  }
}

String _$clockHash() => r'6502f800cf35bdfedf97ad48b01ef21920c1b9f6';
