// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_foreground_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `true` mientras la app está a la vista; en segundo plano no tiene sentido
/// consultar al backend cada pocos segundos.

@ProviderFor(AppForeground)
final appForegroundProvider = AppForegroundProvider._();

/// `true` mientras la app está a la vista; en segundo plano no tiene sentido
/// consultar al backend cada pocos segundos.
final class AppForegroundProvider
    extends $NotifierProvider<AppForeground, bool> {
  /// `true` mientras la app está a la vista; en segundo plano no tiene sentido
  /// consultar al backend cada pocos segundos.
  AppForegroundProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appForegroundProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appForegroundHash();

  @$internal
  @override
  AppForeground create() => AppForeground();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appForegroundHash() => r'285e3051d4f699584cf0171f81d7e01b41b4db80';

/// `true` mientras la app está a la vista; en segundo plano no tiene sentido
/// consultar al backend cada pocos segundos.

abstract class _$AppForeground extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
