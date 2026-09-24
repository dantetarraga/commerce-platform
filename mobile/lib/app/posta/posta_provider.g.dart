// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posta_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Traduce la bolsa y el pedido en curso a la forma de la posta. El pedido
/// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
/// de mostrarse.

@ProviderFor(Posta)
final postaProvider = PostaProvider._();

/// Traduce la bolsa y el pedido en curso a la forma de la posta. El pedido
/// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
/// de mostrarse.
final class PostaProvider extends $NotifierProvider<Posta, PostaView> {
  /// Traduce la bolsa y el pedido en curso a la forma de la posta. El pedido
  /// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
  /// de mostrarse.
  PostaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postaHash();

  @$internal
  @override
  Posta create() => Posta();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostaView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostaView>(value),
    );
  }
}

String _$postaHash() => r'88bf5cb3f6cf86d5e3e720906eed8a1f28d54468';

/// Traduce la bolsa y el pedido en curso a la forma de la posta. El pedido
/// activo tiene prioridad sobre la bolsa; uno entregado y ya calificado deja
/// de mostrarse.

abstract class _$Posta extends $Notifier<PostaView> {
  PostaView build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PostaView, PostaView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostaView, PostaView>,
              PostaView,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
