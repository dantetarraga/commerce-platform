import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Mosaico grande con foto, cuántos negocios hay abiertos y una flecha.
class CategoryPhotoTile extends StatelessWidget {
  const CategoryPhotoTile({
    required this.label,
    required this.caption,
    required this.image,
    required this.height,
    required this.onTap,
    this.open,
    super.key,
  });

  final String label;
  final String? caption;
  final String? image;
  final double height;
  final VoidCallback onTap;

  /// Negocios abiertos ahora en la categoría.
  final int? open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = this.open;
    return AppTapSurface(
      semanticLabel: 'Explorar $label',
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ancho real para que la foto se decodifique a su tamaño en pantalla.
            LayoutBuilder(builder: (context, box) => AppNetworkImage(url: image, width: box.maxWidth, height: box.maxHeight)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1],
                  colors: [AppColors.inkOverlay(0), AppColors.inkOverlay(0.9)],
                ),
              ),
            ),
            if (open != null && open > 0)
              Positioned(
                top: 12,
                left: 12,
                right: 54,
                child: Align(alignment: Alignment.topLeft, child: _OpenCount(open)),
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
                      style: theme.textTheme.bodySmall?.copyWith(color: context.chaski.onPhotoMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenCount extends StatelessWidget {
  const _OpenCount(this.count);

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppColors.inkOverlay(0.85), borderRadius: AppRadius.button),
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
            '$count ${count == 1 ? 'abierto' : 'abiertos'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.blanco),
          ),
        ),
      ],
    ),
  );
}

/// Mosaico mediano con ícono sobre un fondo suave.
class CategorySoftTile extends StatelessWidget {
  const CategorySoftTile({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.height,
    required this.onTap,
    super.key,
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
    return AppTapSurface(
      semanticLabel: 'Explorar $label',
      color: dark ? context.chaski.card : color,
      borderRadius: AppRadius.tileExit,
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
    );
  }
}

/// Franja terracota a todo el ancho (Encargos).
class CategoryStripTile extends StatelessWidget {
  const CategoryStripTile({required this.label, required this.caption, required this.icon, required this.onTap, super.key});

  final String label;
  final String? caption;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppTapSurface(
      semanticLabel: 'Explorar $label',
      color: AppColors.terracota,
      borderRadius: AppRadius.tileExit,
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
                    if (caption != null) Text(caption!, style: theme.textTheme.bodySmall?.copyWith(color: context.chaski.onPhotoMuted)),
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
    );
  }
}

/// Acceso compacto del carril de categorías.
class CategoryCompactTile extends StatelessWidget {
  const CategoryCompactTile({required this.label, required this.icon, required this.highlighted, required this.onTap, super.key});

  final String label;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppTapSurface(
      semanticLabel: 'Explorar $label',
      color: highlighted ? scheme.primaryContainer : context.chaski.card,
      borderRadius: AppRadius.button,
      clip: false,
      onTap: onTap,
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
    );
  }
}
