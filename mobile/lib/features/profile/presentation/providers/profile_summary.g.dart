// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_summary.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileSummary)
final profileSummaryProvider = ProfileSummaryProvider._();

final class ProfileSummaryProvider
    extends $FunctionalProvider<ProfileSummary, ProfileSummary, ProfileSummary>
    with $Provider<ProfileSummary> {
  ProfileSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSummaryHash();

  @$internal
  @override
  $ProviderElement<ProfileSummary> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileSummary create(Ref ref) {
    return profileSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileSummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileSummary>(value),
    );
  }
}

String _$profileSummaryHash() => r'22f50e0c330f79a4686f46626cb6ed016babee43';
