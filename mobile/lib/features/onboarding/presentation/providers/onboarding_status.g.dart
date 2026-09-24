// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `true` si el usuario ya vio el onboarding en este dispositivo.

@ProviderFor(OnboardingStatus)
final onboardingStatusProvider = OnboardingStatusProvider._();

/// `true` si el usuario ya vio el onboarding en este dispositivo.
final class OnboardingStatusProvider
    extends $AsyncNotifierProvider<OnboardingStatus, bool> {
  /// `true` si el usuario ya vio el onboarding en este dispositivo.
  OnboardingStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStatusHash();

  @$internal
  @override
  OnboardingStatus create() => OnboardingStatus();
}

String _$onboardingStatusHash() => r'fa4b6397891f01bce4bbcfb70294f84340ddcfbf';

/// `true` si el usuario ya vio el onboarding en este dispositivo.

abstract class _$OnboardingStatus extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
