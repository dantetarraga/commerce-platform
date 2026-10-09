import 'package:apamuy/features/favorites/domain/favorites.dart';
import 'package:apamuy/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:apamuy/features/favorites/presentation/toggle_favorite.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Corazón sobre la foto de un negocio o producto. Lo inyecta el router para que
/// esas pantallas no dependan de `favorites`.
class FavoriteToggle extends ConsumerWidget {
  const FavoriteToggle.store(this.id, {super.key}) : kind = FavoriteKind.store;

  const FavoriteToggle.product(this.id, {super.key}) : kind = FavoriteKind.product;

  final FavoriteKind kind;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FavoriteButton(
    onPhoto: true,
    isFavorite: ref.watch(switch (kind) {
      FavoriteKind.store => isFavoriteStoreProvider(id),
      FavoriteKind.product => isFavoriteProductProvider(id),
    }),
    onPressed: () => toggleFavorite(context, ref, kind, id),
  );
}
