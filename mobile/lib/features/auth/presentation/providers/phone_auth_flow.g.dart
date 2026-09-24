// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_auth_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PhoneAuthFlow)
final phoneAuthFlowProvider = PhoneAuthFlowProvider._();

final class PhoneAuthFlowProvider
    extends $NotifierProvider<PhoneAuthFlow, PhoneAuthState> {
  PhoneAuthFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneAuthFlowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneAuthFlowHash();

  @$internal
  @override
  PhoneAuthFlow create() => PhoneAuthFlow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneAuthState>(value),
    );
  }
}

String _$phoneAuthFlowHash() => r'4e802a17a575b46c5b3bdb12ba8dfc6db2801486';

abstract class _$PhoneAuthFlow extends $Notifier<PhoneAuthState> {
  PhoneAuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PhoneAuthState, PhoneAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PhoneAuthState, PhoneAuthState>,
              PhoneAuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
