import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/orders/orders.dart';
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
  final history = ref.watch(ordersHistoryProvider).value ?? const [];
  final active = ref.watch(activeOrderProvider).value;
  final favorites = ref.watch(favoritesProvider).value;
  // El pedido activo puede no estar aún en el historial: se cuenta una vez.
  final activeIds = {
    ...history.where((o) => o.isActive).map((o) => o.id),
    if (active != null && active.isActive) active.id,
  };
  return (
    orderCount: history.length,
    activeCount: activeIds.length,
    saved: history.fold(const Money.zero(), (sum, o) => sum + o.discount),
    favoriteCount: favorites == null ? 0 : favorites.storeIds.length + favorites.productIds.length,
    addressCount: ref.watch(addressBookControllerProvider).value?.addresses.length ?? 0,
    latestOrderId: history.firstOrNull?.id,
  );
}
