import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/features/addresses/addresses.dart';
import 'package:apamuy/features/favorites/favorites.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_summary.g.dart';

/// Cifras del perfil: pedidos, en curso, ahorro, favoritos y direcciones.
typedef ProfileSummary = ({
  int orderCount,
  int activeCount,
  Money saved,
  int favoriteCount,
  int addressCount,
  String? latestOrderId,
});

@riverpod
ProfileSummary profileSummary(Ref ref) {
  // Pedidos, en curso, ahorro y el último los cuenta el backend.
  final orders = ref.watch(ordersSummaryProvider).value ?? OrdersSummary.empty;
  final favorites = ref.watch(favoritesProvider).value;
  return (
    orderCount: orders.orderCount,
    activeCount: orders.activeCount,
    saved: orders.saved,
    favoriteCount: favorites == null ? 0 : favorites.storeIds.length + favorites.productIds.length,
    addressCount: ref.watch(addressBookControllerProvider).value?.addresses.length ?? 0,
    latestOrderId: orders.latestOrderId,
  );
}
