import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/shared/design_system/components/app_button.dart';
import 'package:apamuy/shared/design_system/illustrations/empty_art.dart';
import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppEmptyKind {
  /// Nada todavía (bolsa vacía, sin pedidos, sin favoritos).
  empty,

  /// Búsqueda sin coincidencias.
  noResults,

  offline,

  error,

  success,
}

/// Estado vacío: el cuadro de marca con su ícono, una frase, un dato opcional
/// ([extra], p. ej. un [AppEmptyChip]) y una acción.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.message,
    this.kind = AppEmptyKind.empty,
    this.scene,
    this.actionLabel,
    this.onAction,
    this.extra,
    this.compact = false,
    super.key,
  });

  /// Estado a partir de un error: elige escena, título y mensaje del [Failure].
  factory AppEmptyState.fromError(Object error, {VoidCallback? onRetry, bool compact = false, Key? key}) {
    final offline = error is NetworkFailure;
    return AppEmptyState(
      key: key,
      kind: offline ? AppEmptyKind.offline : AppEmptyKind.error,
      title: offline ? 'Se cortó el hilo' : 'Algo se enredó',
      message: offline
          ? 'Revisa tu conexión y lo volvemos a atar.'
          : (error is Failure ? error.message : const ServerFailure().message),
      actionLabel: onRetry == null ? null : 'Intentar de nuevo',
      onAction: onRetry,
      compact: compact,
    );
  }

  final String title;
  final String message;
  final AppEmptyKind kind;

  /// Arte propio; si es nulo se deriva de [kind].
  final AppEmptyArt? scene;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Un dato del momento bajo el mensaje (p. ej. "Hoy salieron 18").
  final Widget? extra;
  final bool compact;

  AppEmptyArt get _scene =>
      scene ??
      switch (kind) {
        AppEmptyKind.empty => AppEmptyArt.emptyBag,
        AppEmptyKind.noResults => AppEmptyArt.search,
        AppEmptyKind.offline => AppEmptyArt.cut,
        AppEmptyKind.error => AppEmptyArt.tangle,
        AppEmptyKind.success => AppEmptyArt.knot,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.md : AppSpacing.xl,
          vertical: compact ? AppSpacing.md : AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyArtView(_scene, size: compact ? 72 : 88),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              Semantics(
                header: true,
                liveRegion: kind == AppEmptyKind.error || kind == AppEmptyKind.offline,
                child: Text(
                  title,
                  style: compact ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (extra case final extra?) ...[
                const SizedBox(height: AppSpacing.sm),
                extra,
              ],
              if (actionLabel != null) ...[
                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                AppButton.secondary(
                  label: actionLabel!,
                  onPressed: onAction,
                  expand: false,
                  size: compact ? AppButtonSize.sm : AppButtonSize.md,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dato corto bajo un estado vacío. Con [live] lleva el punto verde de "en
/// curso"; con [onTap] es un enlace lleno ("2 nuevas esperando →").
class AppEmptyChip extends StatelessWidget {
  const AppEmptyChip({required this.label, this.live = false, this.onTap, super.key});

  final String label;
  final bool live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final link = onTap != null;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: link ? scheme.primary : scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: link ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.hierba, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: link ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
    if (!link) return chip;
    return Semantics(button: true, child: GestureDetector(onTap: onTap, child: chip));
  }
}
