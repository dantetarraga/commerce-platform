import 'dart:async';

import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

enum AppToastKind { info, success, undo, error }

/// Aviso breve que aparece arriba de la posta (nunca la tapa) y se va solo.
///
/// `AppToast.show(context, 'Eliminado', kind: AppToastKind.undo, onAction: …)`.
abstract final class AppToast {
  static OverlayEntry? _current;
  static Timer? _timer;

  /// Distancia al borde inferior: deja libre la barra de navegación + posta.
  static double bottomOffset = 150;

  static void show(
    BuildContext context,
    String message, {
    AppToastKind kind = AppToastKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    dismiss();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        kind: kind,
        actionLabel: actionLabel ?? (kind == AppToastKind.undo ? 'Deshacer' : null),
        onAction: onAction == null
            ? null
            : () {
                dismiss();
                onAction();
              },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    _timer = Timer(duration ?? (kind == AppToastKind.undo ? const Duration(seconds: 4) : const Duration(milliseconds: 2600)), dismiss);
    // Accesibilidad: se anuncia además de mostrarse.
    SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context)).ignore();
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.message, required this.kind, this.actionLabel, this.onAction});

  final String message;
  final AppToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    // El toast usa la superficie inversa: tinta en claro, casi blanco en oscuro.
    final lightUi = theme.brightness == Brightness.light;
    final (IconData icon, Color iconColor) = switch (kind) {
      AppToastKind.info => (Icons.info_outline_rounded, scheme.onInverseSurface),
      AppToastKind.success => (Icons.check_circle_rounded, lightUi ? chaski.accent : AppColors.exito),
      AppToastKind.undo => (Icons.undo_rounded, scheme.onInverseSurface),
      AppToastKind.error => (Icons.error_outline_rounded, lightUi ? AppColors.peligro300 : AppColors.peligro),
    };
    final bottom = MediaQuery.paddingOf(context).bottom + AppToast.bottomOffset;

    return Positioned(
      left: AppSpacing.gutter,
      right: AppSpacing.gutter,
      bottom: bottom,
      child: SafeArea(
        top: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
          curve: AppMotion.postaOut,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
          ),
          child: Material(
            color: scheme.inverseSurface,
            borderRadius: AppRadius.tile,
            elevation: 6,
            shadowColor: scheme.shadow.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface)),
                    ),
                    if (actionLabel != null && onAction != null)
                      TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(foregroundColor: scheme.inversePrimary),
                        child: Text(actionLabel!),
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
