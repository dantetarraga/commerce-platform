import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/home/presentation/widgets/city_categories.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Los accesos a categorías, ordenados por el momento del día.
class CategoryShelf extends ConsumerWidget {
  const CategoryShelf({super.key});

  /// Orden de los 4 principales (por `slug`); si falta alguno, entra el siguiente.
  static const _main = ['restaurantes', 'mercado', 'farmacia', 'bodegas', 'postres', 'licores', 'regalos', 'encargos'];

  /// Elige los 4 accesos y cuál resaltar según el momento.
  static ({List<Category> main, List<Category> rest, String? highlighted}) pick(List<Category> all, Moment moment) {
    int rank(Category c) {
      final i = _main.indexOf(c.slug);
      return i < 0 ? _main.length : i;
    }

    final sorted = [...all]..sort((a, b) => rank(a).compareTo(rank(b)));
    final main = sorted.take(4).toList();
    // Si la categoría del momento no está entre las 4, reemplaza a la última.
    final featured = moment.featuredCategories.map((slug) => all.where((c) => c.slug == slug).firstOrNull).nonNulls.firstOrNull;
    if (featured != null && !main.contains(featured) && main.length == 4) {
      main[3] = featured;
    }
    return (
      main: main,
      rest: [
        for (final c in sorted)
          if (!main.contains(c)) c,
      ],
      highlighted: featured?.slug,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(currentMomentProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: AsyncValueView(
        value: ref.watch(categoriesProvider),
        compactError: true,
        onRetry: () => ref.invalidate(categoriesProvider),
        loading: const CityCategoriesSkeleton(),
        data: (categories) {
          final picked = pick(categories, moment);
          return CityCategories(
            categories: [...picked.main, ...picked.rest],
            highlighted: picked.highlighted,
            openCount: {for (final c in categories) c.id: c.openStoreCount},
          );
        },
      ),
    );
  }
}
