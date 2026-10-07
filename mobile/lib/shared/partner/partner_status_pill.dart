import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// "Cocina abierta · recibiendo" / "En ruta · conectado": verde cuando está activo.
class PartnerStatusPill extends StatelessWidget {
  const PartnerStatusPill({
    required this.title,
    required this.message,
    required this.value,
    required this.onChanged,
    this.busy = false,
    super.key,
  });

  final String title;
  final String message;
  final bool value;
  final bool busy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = value;
    final bg = on ? AppColors.hierba : scheme.surface;
    final fg = on ? AppColors.blanco : scheme.onSurface;
    return Material(
      color: bg,
      borderRadius: AppRadius.tileExit,
      shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.tileExit,
        onTap: busy || onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(borderRadius: AppRadius.tileExit, boxShadow: AppShadows.raised(theme.brightness)),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: on ? AppColors.blanco : scheme.onSurfaceVariant, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(color: on ? AppColors.onPhotoMuted : scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: AppLoader(size: 22)),
                )
              else
                Semantics(
                  label: title,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: AppColors.blanco,
                    activeTrackColor: AppColors.blanco.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lugar de la píldora de estado mientras carga (misma altura y esquina).
class PartnerStatusPillSkeleton extends StatelessWidget {
  const PartnerStatusPillSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.tileExit,
      boxShadow: AppShadows.raised(Theme.of(context).brightness),
    ),
    child: const Skeleton(
      child: Row(
        children: [
          SkeletonBox.circle(size: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [SkeletonBox(width: 170), SizedBox(height: 6), SkeletonBox(width: 130, height: 10)],
            ),
          ),
          SkeletonBox(width: 52, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
        ],
      ),
    ),
  );
}
