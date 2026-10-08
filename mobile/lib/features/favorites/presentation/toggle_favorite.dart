import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/favorites/domain/favorites.dart';
import 'package:apamuy/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Corazón de favoritos: cambia al instante y avisa si no se pudo guardar.
Future<void> toggleFavorite(BuildContext context, WidgetRef ref, FavoriteKind kind, String id) async {
  final result = await ref.read(favoritesProvider.notifier).toggle(kind, id);
  if (result case Err(:final failure) when context.mounted) {
    AppToast.show(context, failure.message, kind: AppToastKind.error);
  }
}
