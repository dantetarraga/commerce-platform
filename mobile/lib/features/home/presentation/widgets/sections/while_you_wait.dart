import 'package:apamuy/features/discovery/discovery.dart';
import 'package:apamuy/features/stores/stores.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Mientras hay un pedido en curso: buscar algo más y cuatro accesos.
class WhileYouWait extends ConsumerWidget {
  const WhileYouWait({super.key});

  static const _slugs = ['restaurantes', 'bodegas', 'farmacia', 'encargos'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final picked = [
      for (final slug in _slugs) ?categories.where((c) => c.slug == slug).firstOrNull,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            hints: const ['¿Algo más mientras esperas?', 'Busca comida, tiendas o productos'],
            variant: AppSearchBarVariant.compact,
            onTap: () => context.goNamed(ExplorePage.name),
          ),
          if (picked.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text('Mientras esperas', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final (i, c) in picked.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _WaitTile(category: c, alternate: i.isOdd)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WaitTile extends StatelessWidget {
  const _WaitTile({required this.category, required this.alternate});

  final Category category;

  /// Alterna el fondo suave (terracota / hierba) en claro.
  final bool alternate;

  String get _label => category.slug == 'restaurantes' ? 'Comida' : categoryShelfLabel(category.slug, category.name);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final strong = category.slug == 'encargos';
    final fg = strong ? AppColors.blanco : (dark ? theme.colorScheme.onSurface : AppColors.tinta);
    final bg = strong ? AppColors.terracota : (dark ? context.apamuy.card : (alternate ? AppColors.hierbaSoft : AppColors.terracota50));
    return AppTapSurface(
      semanticLabel: 'Explorar $_label',
      color: bg,
      borderRadius: AppRadius.button,
      pressScale: 1,
      onTap: () => context.pushNamed(CategoryStoresPage.name, pathParameters: {'categoryId': category.id}),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(categoryVisuals(category.slug).icon, color: fg),
              const SizedBox(height: 4),
              Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
