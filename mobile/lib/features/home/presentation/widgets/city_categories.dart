import 'package:apamuy/core/utils/text_scale.dart';
import 'package:apamuy/features/home/presentation/widgets/category_tiles.dart';
import 'package:apamuy/features/stores/stores.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Con texto grande los mosaicos crecen en vez de cortar las etiquetas.
double _sideHeight(BuildContext context) => 112 + textScaleExtra(context) * 2;

double _compactHeight(BuildContext context) => 70 + MediaQuery.textScalerOf(context).scale(16);

/// Categorías con jerarquía: Restaurantes en grande con foto, dos accesos
/// medianos al lado, Encargos como franja y el resto en un carril compacto.
class CityCategories extends StatelessWidget {
  const CityCategories({required this.categories, required this.highlighted, this.openCount = const {}, super.key});

  final List<Category> categories;
  final String? highlighted;

  /// Negocios abiertos ahora por id de categoría.
  final Map<String, int> openCount;

  static String _label(Category c) => categoryShelfLabel(c.slug, c.name);

  /// Una línea que dice qué se encuentra, sin inventar cifras.
  static String? _caption(Category c) => switch (c.slug) {
    'restaurantes' => 'Almuerzos, pollos y más',
    'bodegas' => 'Abarrotes al paso',
    'farmacia' => 'Botiquín y cuidado',
    'mercado' => 'Frutas y verduras',
    'postres' => 'Tortas y dulces',
    'licores' => 'Para la reunión',
    'regalos' => 'Flores y detalles',
    'encargos' => 'Recogemos y te lo traemos',
    _ => null,
  };

  static String? _image(Category c) => c.iconUrl?.isNotEmpty == true ? c.iconUrl : 'assets/images/demo/burger.jpg';

  void _open(BuildContext context, Category c) => context.pushNamed(CategoryStoresPage.name, pathParameters: {'categoryId': c.id});

  @override
  Widget build(BuildContext context) {
    final big = categories.where((c) => c.slug == 'restaurantes').firstOrNull ?? categories.firstOrNull;
    if (big == null) return const SizedBox.shrink();
    final strip = categories.where((c) => c.slug == 'encargos' && c != big).firstOrNull;
    final side = categories.where((c) => c != big && c != strip).take(2).toList();
    final rest = categories.where((c) => c != big && c != strip && !side.contains(c)).toList();
    final sideHeight = _sideHeight(context);

    Widget compact(Category c) => CategoryCompactTile(
      label: _label(c),
      icon: categoryVisuals(c.slug).icon,
      highlighted: c.slug == highlighted,
      onTap: () => _open(context, c),
    );

    return Column(
      children: [
        Padding(
          padding: AppSpacing.screen,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: CategoryPhotoTile(
                  label: _label(big),
                  caption: _caption(big),
                  image: _image(big),
                  open: openCount[big.id],
                  height: sideHeight * 2 + 12,
                  onTap: () => _open(context, big),
                ),
              ),
              if (side.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      for (final (i, c) in side.indexed) ...[
                        if (i > 0) const SizedBox(height: 12),
                        CategorySoftTile(
                          label: _label(c),
                          caption: _caption(c),
                          icon: categoryVisuals(c.slug).icon,
                          color: i == 0 ? AppColors.terracota50 : AppColors.hierbaSoft,
                          height: sideHeight,
                          onTap: () => _open(context, c),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (strip != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 12, AppSpacing.gutter, 0),
            child: CategoryStripTile(
              label: _label(strip),
              caption: _caption(strip),
              icon: categoryVisuals(strip.slug).icon,
              onTap: () => _open(context, strip),
            ),
          ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: _compactHeight(context),
            // Hasta cuatro caben repartidos en el ancho; más, en un carril.
            child: rest.length <= 4
                ? Padding(
                    padding: AppSpacing.screen,
                    child: Row(
                      children: [
                        for (final (i, c) in rest.indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: compact(c)),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: AppSpacing.screen,
                    itemCount: rest.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => compact(rest[index]),
                  ),
          ),
        ],
      ],
    );
  }
}

/// Misma geometría del mosaico: foto grande, dos mosaicos suaves, la franja de
/// encargos y la fila compacta.
class CityCategoriesSkeleton extends StatelessWidget {
  const CityCategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final sideHeight = _sideHeight(context);
    return Skeleton(
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: Row(
              children: [
                Expanded(flex: 11, child: SkeletonBox(height: sideHeight * 2 + 12, borderRadius: AppRadius.card)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      SkeletonBox(height: sideHeight, borderRadius: AppRadius.tileExit),
                      const SizedBox(height: 12),
                      SkeletonBox(height: sideHeight, borderRadius: AppRadius.tileExit),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 12, AppSpacing.gutter, 0),
            child: SkeletonBox(height: 76, borderRadius: AppRadius.tileExit),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: AppSpacing.screen,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: _compactHeight(context), borderRadius: AppRadius.button)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
