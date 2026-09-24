// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_searches.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Últimas búsquedas (máximo [max]), guardadas en el dispositivo.

@ProviderFor(RecentSearches)
final recentSearchesProvider = RecentSearchesProvider._();

/// Últimas búsquedas (máximo [max]), guardadas en el dispositivo.
final class RecentSearchesProvider
    extends $AsyncNotifierProvider<RecentSearches, List<String>> {
  /// Últimas búsquedas (máximo [max]), guardadas en el dispositivo.
  RecentSearchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchesHash();

  @$internal
  @override
  RecentSearches create() => RecentSearches();
}

String _$recentSearchesHash() => r'041499e225095b23740f1d9ad75ac9901bab58ab';

/// Últimas búsquedas (máximo [max]), guardadas en el dispositivo.

abstract class _$RecentSearches extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
