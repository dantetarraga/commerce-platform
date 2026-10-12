import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// La carta vacía: las formas de empezar, la más rápida primero.
class MenuStartOptions extends StatelessWidget {
  const MenuStartOptions({required this.onImport, required this.onCreate, super.key});

  final VoidCallback onImport;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xl),
      children: [
        Semantics(
          header: true,
          child: Text('Todavía no tienes productos.', style: AppTypography.displayStyle(context, size: 24)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Elige cómo empezar. Puedes subir todo de una vez y luego afinar uno por uno.', style: muted),
        const SizedBox(height: AppSpacing.lg),
        _StartOption(
          icon: Icons.table_view_rounded,
          title: 'Desde Excel o CSV',
          tag: 'Más rápido',
          message: 'Llena la plantilla con toda tu carta y súbela. Antes de guardar te mostramos qué cambia.',
          highlighted: true,
          onTap: onImport,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StartOption(
          icon: Icons.add_rounded,
          title: 'Uno por uno',
          message: 'Con foto de la cámara, precio y sección. Ideal si son pocos productos.',
          onTap: onCreate,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _StartOption(
          icon: Icons.photo_camera_outlined,
          title: 'Foto de tu carta impresa',
          tag: 'Pronto',
          message: 'Le tomas foto a tu carta y la armamos por ti para que solo la revises.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('También puedes hacerlo desde el Portal Socios web.', style: muted, textAlign: TextAlign.center),
      ],
    );
  }
}

class _StartOption extends StatelessWidget {
  const _StartOption({
    required this.icon,
    required this.title,
    required this.message,
    this.tag,
    this.highlighted = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? tag;
  final bool highlighted;

  /// Sin acción: todavía no está disponible.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final apamuy = context.apamuy;
    final enabled = onTap != null;
    final fg = enabled ? scheme.onSurface : scheme.onSurfaceVariant;
    return Semantics(
      button: enabled,
      enabled: enabled,
      child: Material(
        color: enabled ? apamuy.card : apamuy.raised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.tile,
          side: highlighted
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide(color: enabled ? scheme.outlineVariant : Colors.transparent),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: highlighted ? scheme.primary : (enabled ? apamuy.raised : scheme.surface),
                    borderRadius: AppRadius.tile,
                  ),
                  child: Icon(icon, color: highlighted ? scheme.onPrimary : fg),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: theme.textTheme.titleSmall?.copyWith(color: fg)),
                          if (tag != null) _Tag(label: tag!, strong: enabled),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.strong});

  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apamuy = context.apamuy;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: strong ? apamuy.success : theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: strong ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
