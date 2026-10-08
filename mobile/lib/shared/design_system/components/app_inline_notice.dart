import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/shared/design_system/components/app_button.dart';
import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppNoticeKind {
  /// Dato útil o aviso neutro ("El negocio cierra en 20 min").
  info,

  /// Algo que pide atención pero no bloquea ("Falta S/ 4 para el mínimo").
  warning,

  /// Algo falló (error de formulario, no se pudo cargar una sección).
  error,
}

/// Aviso dentro del flujo: ícono, mensaje y una acción opcional. Para errores a
/// pantalla completa usa `AppEmptyState.fromError`; para algo pasajero, un toast.
class AppInlineNotice extends StatelessWidget {
  const AppInlineNotice({
    required this.message,
    this.kind = AppNoticeKind.info,
    this.actionLabel,
    this.onAction,
    this.boxed = true,
    super.key,
  });

  /// Aviso de error a partir de un [Failure]: sin conexión da un mensaje humano.
  factory AppInlineNotice.fromError(Object error, {VoidCallback? onRetry, bool boxed = true, Key? key}) => AppInlineNotice(
    key: key,
    kind: AppNoticeKind.error,
    message: messageFor(error),
    actionLabel: onRetry == null ? null : 'Reintentar',
    onAction: onRetry,
    boxed: boxed,
  );

  final String message;
  final AppNoticeKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool boxed;

  /// Texto para el usuario de un error cualquiera.
  static String messageFor(Object error) => switch (error) {
    NetworkFailure() => 'Se cortó el hilo. Revisa tu conexión y vuelve a intentarlo.',
    Failure(:final message) => message,
    _ => const ServerFailure().message,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (IconData icon, Color color) = switch (kind) {
      AppNoticeKind.info => (Icons.info_outline_rounded, scheme.onSurface),
      AppNoticeKind.warning => (Icons.schedule_rounded, scheme.primary),
      AppNoticeKind.error => (Icons.error_outline_rounded, context.apamuy.danger),
    };
    final text = Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: boxed ? null : FontWeight.w600),
    );
    final row = Row(
      crossAxisAlignment: boxed ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: boxed ? 20 : 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: text),
      ],
    );
    final content = actionLabel == null
        ? row
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              row,
              Padding(
                padding: const EdgeInsets.only(left: 20 + AppSpacing.xs - AppSpacing.sm),
                child: AppButton.ghost(label: actionLabel!, size: AppButtonSize.sm, onPressed: onAction),
              ),
            ],
          );
    return Semantics(
      liveRegion: true,
      child: boxed
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: kind == AppNoticeKind.info ? context.apamuy.raised : color.withValues(alpha: 0.08),
                borderRadius: AppRadius.tile,
              ),
              child: content,
            )
          : content,
    );
  }
}
