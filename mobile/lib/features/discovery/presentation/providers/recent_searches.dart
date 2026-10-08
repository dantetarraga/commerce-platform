import 'package:apamuy/core/storage/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_searches.g.dart';

/// Últimas búsquedas (máximo [max]), guardadas en el dispositivo.
@Riverpod(keepAlive: true)
class RecentSearches extends _$RecentSearches {
  static const max = 6;
  static const _key = 'apamuy.recentSearches';

  @override
  Future<List<String>> build() async {
    final json = await ref.watch(localJsonStoreProvider).read(_key);
    return json is List ? json.whereType<String>().take(max).toList() : const [];
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    final current = state.value ?? const [];
    final next = [q, ...current.where((c) => c.toLowerCase() != q.toLowerCase())].take(max).toList();
    state = AsyncData(next);
    await ref.read(localJsonStoreProvider).write(_key, next);
  }

  Future<void> remove(String query) async {
    final next = (state.value ?? const []).where((c) => c != query).toList();
    state = AsyncData(next);
    await ref.read(localJsonStoreProvider).write(_key, next);
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await ref.read(localJsonStoreProvider).remove(_key);
  }
}
