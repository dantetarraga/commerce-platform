import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Categorías con jerarquía: Restaurantes en grande con foto, dos accesos medianos al
/// lado, Encargos como franja y el resto en un carril compacto.
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
    final strip = categories.where((c) => c.slug == 'encargos' && c != big).firstOrNull;
    final side = categories.where((c) => c != big && c != strip).take(2).toList();
    final rest = categories.where((c) => c != big && c != strip && !side.contains(c)).toList();
    if (big == null) return const SizedBox.shrink();

    // Con texto grande los mosaicos crecen en vez de cortar las etiquetas.
    final extra = (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0.0, 24.0) * 2;
    final sideHeight = 112 + extra;

    return Column(
      children: [
        Padding(
          padding: AppSpacing.screen,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: _PhotoTile(
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
                        _SoftTile(
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
            child: _StripTile(
              label: _label(strip),
              caption: _caption(strip),
              icon: categoryVisuals(strip.slug).icon,
              onTap: () => _open(context, strip),
            ),
          ),
        if (rest.isNotEmpty && rest.length <= 4) ...[
          const SizedBox(height: 12),
          Padding(
            padding: AppSpacing.screen,
            child: SizedBox(
              height: 70 + MediaQuery.textScalerOf(context).scale(16),
              child: Row(
                children: [
                  for (final (i, c) in rest.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _CompactTile(
                        label: _label(c),
                        icon: categoryVisuals(c.slug).icon,
                        highlighted: c.slug == highlighted,
                        onTap: () => _open(context, c),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ] else if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 70 + MediaQuery.textScalerOf(context).scale(16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screen,
              itemCount: rest.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final c = rest[index];
                return _CompactTile(
                  label: _label(c),
                  icon: categoryVisuals(c.slug).icon,
                  highlighted: c.slug == highlighted,
                  onTap: () => _open(context, c),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.label, required this.caption, required this.image, required this.height, required this.onTap, this.open});

  final int? open;
  final String label;
  final String? caption;
  final String? image;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Explorar $label',
      onTap: onTap,
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          borderRadius: AppRadius.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: image),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1],
                        colors: [Color(0x002A1A14), Color(0xE62A1A14)],
                      ),
                    ),
                  ),
                  if (open != null && open! > 0)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 54,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: const BoxDecoration(color: Color(0xD92A1A14), borderRadius: AppRadius.button),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(color: AppColors.hierba300, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${open!} ${open == 1 ? 'abierto' : 'abiertos'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.blanco),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: AppColors.terracota, borderRadius: AppRadius.button),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.blanco),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(label, maxLines: 1, style: theme.textTheme.titleLarge?.copyWith(color: AppColors.blanco)),
                        ),
                        if (caption != null)
                          Text(
                            caption!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFF1E6DE)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftTile extends StatelessWidget {
  const _SoftTile({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.height,
    required this.onTap,
  });

  final String label;
  final String? caption;
  final IconData icon;
  final Color color;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fg = dark ? theme.colorScheme.onSurface : AppColors.tinta;
    return Semantics(
      button: true,
      label: 'Explorar $label',
      onTap: onTap,
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: dark ? context.chaski.raised : color,
          borderRadius: AppRadius.tileExit,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 30, color: fg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(label, maxLines: 1, style: theme.textTheme.titleMedium?.copyWith(color: fg)),
                        ),
                        if (caption != null)
                          Text(
                            caption!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: dark ? theme.colorScheme.onSurfaceVariant : AppColors.piedra),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripTile extends StatelessWidget {
  const _StripTile({required this.label, required this.caption, required this.icon, required this.onTap});

  final String label;
  final String? caption;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Explorar $label',
      onTap: onTap,
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: AppColors.terracota,
          borderRadius: AppRadius.tileExit,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 34, color: AppColors.blanco),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.blanco)),
                          if (caption != null) Text(caption!, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFFFF3EE))),
                        ],
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.terracota),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({required this.label, required this.icon, required this.highlighted, required this.onTap});

  final String label;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: 'Explorar $label',
      onTap: onTap,
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: highlighted ? scheme.primaryContainer : (theme.brightness == Brightness.dark ? context.chaski.raised : AppColors.blanco),
          borderRadius: AppRadius.button,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.button,
            child: SizedBox(
              width: 80,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26, color: highlighted ? scheme.primary : scheme.onSurface),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
