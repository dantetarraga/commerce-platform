// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_mode_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Modo que el socio eligió la última vez, guardado en el dispositivo.

@ProviderFor(PartnerModePreference)
final partnerModePreferenceProvider = PartnerModePreferenceProvider._();

/// Modo que el socio eligió la última vez, guardado en el dispositivo.
final class PartnerModePreferenceProvider
    extends $NotifierProvider<PartnerModePreference, PartnerMode?> {
  /// Modo que el socio eligió la última vez, guardado en el dispositivo.
  PartnerModePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partnerModePreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partnerModePreferenceHash();

  @$internal
  @override
  PartnerModePreference create() => PartnerModePreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartnerMode? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartnerMode?>(value),
    );
  }
}

String _$partnerModePreferenceHash() =>
    r'433b35c73da81faf866f06d53a0021a1f86d2c0f';

/// Modo que el socio eligió la última vez, guardado en el dispositivo.

abstract class _$PartnerModePreference extends $Notifier<PartnerMode?> {
  PartnerMode? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PartnerMode?, PartnerMode?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PartnerMode?, PartnerMode?>,
              PartnerMode?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Modos a los que puede entrar el usuario con sesión.

@ProviderFor(availablePartnerModesFor)
final availablePartnerModesForProvider = AvailablePartnerModesForProvider._();

/// Modos a los que puede entrar el usuario con sesión.

final class AvailablePartnerModesForProvider
    extends
        $FunctionalProvider<
          List<PartnerMode>,
          List<PartnerMode>,
          List<PartnerMode>
        >
    with $Provider<List<PartnerMode>> {
  /// Modos a los que puede entrar el usuario con sesión.
  AvailablePartnerModesForProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availablePartnerModesForProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availablePartnerModesForHash();

  @$internal
  @override
  $ProviderElement<List<PartnerMode>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<PartnerMode> create(Ref ref) {
    return availablePartnerModesFor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PartnerMode> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PartnerMode>>(value),
    );
  }
}

String _$availablePartnerModesForHash() =>
    r'90510da3803e76132758aa44be3b87f0e6902e9b';

/// Modo activo: el elegido si sigue siendo válido, o el primero disponible.

@ProviderFor(activePartnerMode)
final activePartnerModeProvider = ActivePartnerModeProvider._();

/// Modo activo: el elegido si sigue siendo válido, o el primero disponible.

final class ActivePartnerModeProvider
    extends $FunctionalProvider<PartnerMode?, PartnerMode?, PartnerMode?>
    with $Provider<PartnerMode?> {
  /// Modo activo: el elegido si sigue siendo válido, o el primero disponible.
  ActivePartnerModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePartnerModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePartnerModeHash();

  @$internal
  @override
  $ProviderElement<PartnerMode?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PartnerMode? create(Ref ref) {
    return activePartnerMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartnerMode? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartnerMode?>(value),
    );
  }
}

String _$activePartnerModeHash() => r'0f76b17fbe0ab754c6986224e89b60741c72d97f';
