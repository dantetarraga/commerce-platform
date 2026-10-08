import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Cabecera de color de las pantallas de trabajo de Apamuy Socios: volver, etiqueta,
/// titular con su remate en terracota y una métrica o [trailing] a la derecha.
class PartnerPageHeader extends StatelessWidget {
  const PartnerPageHeader({
    required this.eyebrow,
    required this.title,
    this.accent = '',
    this.leading,
    this.showBack = true,
    this.metricLabel,
    this.metric,
    this.trailing = const [],
    this.titleSize = 22,
    this.safeTop = false,
    this.skeleton = false,
    super.key,
  });

  /// Cabecera de carga: mismo alto, con cajas en lugar de textos.
  const PartnerPageHeader.skeleton({this.showBack = true, this.titleSize = 22, this.safeTop = false, super.key})
    : eyebrow = '',
      title = '',
      accent = '',
      leading = null,
      metricLabel = null,
      metric = null,
      trailing = const [],
      skeleton = true;

  /// "RECORRIDO 3104 · PASO 1 DE 2" (ya en mayúsculas).
  final String eyebrow;

  /// Primera parte del titular: "Tu carta, ".
  final String title;

  /// Remate en terracota: "al día.".
  final String accent;

  /// Algo antes del texto, p. ej. un `PartnerStoreLogo` (sin botón de volver).
  final Widget? leading;

  /// Botón de volver de 48 px. Se ignora si hay [leading].
  final bool showBack;

  /// Métrica a la derecha: etiqueta pequeña ("Entrega a") y valor ("850 m").
  final String? metricLabel;
  final String? metric;

  /// Acciones o widgets al final de la fila.
  final List<Widget> trailing;
  final double titleSize;

  /// Suma el alto de la barra de estado (cuando va en lugar de un `AppBar`).
  final bool safeTop;
  final bool skeleton;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = safeTop ? MediaQuery.paddingOf(context).top : 0.0;
    final leading = this.leading;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.header),
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, top + AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: AppSpacing.sm)] else if (showBack) ...[
            const _BackButton(),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: skeleton ? _TitleSkeleton(titleSize: titleSize) : _Title(eyebrow: eyebrow, title: title, accent: accent, size: titleSize)),
          if (skeleton)
            const _MetricSkeleton()
          else if (metric != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _Metric(label: metricLabel, value: metric!),
          ],
          ...trailing,
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Volver',
      onPressed: () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(backgroundColor: scheme.surface, fixedSize: const Size.square(AppSpacing.minTouch)),
      icon: const Icon(Icons.arrow_back_rounded, size: 20),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.eyebrow, required this.title, required this.accent, required this.size});

  final String eyebrow;
  final String title;
  final String accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer, letterSpacing: 1.2, fontWeight: FontWeight.w800),
        ),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              text: title,
              children: [if (accent.isNotEmpty) TextSpan(text: accent, style: TextStyle(color: scheme.primary))],
            ),
            style: AppTypography.displayStyle(context, size: size, weight: FontWeight.w800, height: 1.1),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, this.label});

  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = this.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (label != null) Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: AppTypography.price(context, size: 22)),
      ],
    );
  }
}

class _TitleSkeleton extends StatelessWidget {
  const _TitleSkeleton({required this.titleSize});

  final double titleSize;

  @override
  Widget build(BuildContext context) => Skeleton(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const SkeletonBox(width: 170, height: 10), const SizedBox(height: 8), SkeletonBox(width: 180, height: titleSize)],
    ),
  );
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton();

  @override
  Widget build(BuildContext context) => const Skeleton(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [SkeletonBox(width: 56, height: 10), SizedBox(height: 8), SkeletonBox(width: 64, height: 22)],
    ),
  );
}
