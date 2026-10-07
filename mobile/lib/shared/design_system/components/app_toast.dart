import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:toastification/toastification.dart';

enum AppToastKind { info, success, undo, error }

/// Aviso breve que baja desde arriba (lejos de la barra de compra y la
/// navegación) y se va solo. Se desliza para cerrarlo y, mientras se mantiene
/// presionado, no se va.
///
/// `AppToast.show(context, 'Eliminado', kind: AppToastKind.undo, onAction: …)`.
///
/// Es el adaptador del paquete de toasts: **nada fuera de este archivo importa
/// `toastification`**. Para cambiar de paquete basta con reescribir [show] y
/// [dismiss]; las llamadas de la app no cambian.
abstract final class AppToast {
  /// Como mucho dos a la vez: el más viejo se va cuando llega un tercero.
  static const _maxVisible = 2;
  static final _visible = <ToastificationItem>[];

  static void show(
    BuildContext context,
    String message, {
    AppToastKind kind = AppToastKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    Widget? leading,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final reduced = reduceMotionOf(context);
    final label = actionLabel ?? (kind == AppToastKind.undo ? 'Deshacer' : null);
    final life = duration ?? (label != null ? const Duration(seconds: 4) : const Duration(milliseconds: 2600));

    late final ToastificationItem item;
    item = toastification.showCustom(
      context: context,
      overlayState: overlay,
      alignment: Alignment.topCenter,
      autoCloseDuration: life,
      animationDuration: reduced ? Duration.zero : AppMotion.move,
      animationBuilder: (context, animation, _, child) => _enterFromTop(animation, child),
      callbacks: ToastificationCallbacks(onDismissed: _visible.remove, onAutoCompleteCompleted: _visible.remove),
      builder: (context, holder) => _ToastView(
        holder: holder,
        message: message,
        kind: kind,
        life: life,
        leading: leading,
        actionLabel: label,
        onAction: onAction == null
            ? null
            : () {
                _dismiss(holder);
                onAction();
              },
      ),
    );
    _visible.add(item);
    while (_visible.length > _maxVisible) {
      _dismiss(_visible.first);
    }
    if (kind == AppToastKind.error) HapticFeedback.mediumImpact().ignore();
    // Accesibilidad: se anuncia además de mostrarse.
    SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context)).ignore();
  }

  /// Cierra todos al instante (p. ej. al salir de una pantalla o en tests).
  static void dismiss() {
    _visible.clear();
    toastification.dismissAll(delayForAnimation: false);
  }

  static void _dismiss(ToastificationItem item) {
    _visible.remove(item);
    toastification.dismiss(item);
  }

  /// Baja desde arriba con un leve rebote; se va subiendo y desvaneciéndose.
  static Widget _enterFromTop(Animation<double> animation, Widget child) {
    final slide = CurvedAnimation(parent: animation, curve: AppMotion.knot, reverseCurve: AppMotion.depart);
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.5)),
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(slide),
        child: child,
      ),
    );
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.holder,
    required this.message,
    required this.kind,
    required this.life,
    this.actionLabel,
    this.onAction,
    this.leading,
  });

  final ToastificationItem holder;
  final String message;
  final AppToastKind kind;
  final Duration life;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? leading;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  // La lista del paquete recrea este estado cuando llega otro aviso encima: la
  // barra parte de lo que ya corrió el timer y la entrada no se repite.
  late final double _startLeft = _remaining();
  late final bool _fresh = _startLeft > 0.9;

  // Lo que le queda de vida al aviso (1 → 0), sincronizado con su timer.
  late final _left = AnimationController(vsync: this, duration: widget.life, value: _startLeft)..reverse();

  double _remaining() {
    final elapsed = widget.holder.elapsedDuration;
    if (elapsed == null) return 1;
    return (1 - elapsed.inMicroseconds / widget.life.inMicroseconds).clamp(0.0, 1.0);
  }

  void _hold(bool held) {
    if (held) {
      widget.holder.pause();
      _left.stop();
    } else {
      widget.holder.start();
      _left.reverse();
    }
  }

  @override
  void dispose() {
    _left.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduced = reduceMotionOf(context);
    final light = theme.brightness == Brightness.light;
    final (IconData icon, Color tone) = switch (widget.kind) {
      AppToastKind.info => (Icons.info_rounded, scheme.primary),
      AppToastKind.success => (Icons.check_rounded, light ? AppColors.exito : AppColors.exito300),
      AppToastKind.undo => (Icons.undo_rounded, scheme.onSurface),
      AppToastKind.error => (Icons.priority_high_rounded, light ? AppColors.peligro : AppColors.peligro300),
    };

    var badge =
        widget.leading ??
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: tone, borderRadius: AppRadius.button),
          child: Icon(icon, size: 20, color: light ? AppColors.blanco : AppColors.noche),
        );
    if (!reduced && _fresh) {
      // El ícono salta al llegar; si es un error, además se sacude.
      var entrance = badge
          .animate(delay: const Duration(milliseconds: 120))
          .scaleXY(begin: 0.4, end: 1, duration: AppMotion.move, curve: AppMotion.knot);
      if (widget.kind == AppToastKind.error) entrance = entrance.shakeX(hz: 5, amount: 3);
      badge = entrance;
    }

    return Dismissible(
      key: ValueKey(widget.holder.id),
      direction: DismissDirection.up,
      onDismissed: (_) => toastification.dismiss(widget.holder, showRemoveAnimation: false),
      child: Listener(
        onPointerDown: (_) => _hold(true),
        onPointerUp: (_) => _hold(false),
        onPointerCancel: (_) => _hold(false),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
          child: Material(
            color: light ? AppColors.blanco : scheme.surfaceContainerHigh,
            borderRadius: AppRadius.tileExit,
            clipBehavior: Clip.antiAlias,
            elevation: 10,
            shadowColor: AppColors.tinta.withValues(alpha: 0.35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, widget.actionLabel == null ? AppSpacing.md : AppSpacing.xxs, AppSpacing.sm),
                  child: Row(
                    children: [
                      badge,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (widget.actionLabel != null && widget.onAction != null)
                        TextButton(
                          onPressed: widget.onAction,
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                            minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
                            textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          child: Text(widget.actionLabel!),
                        ),
                    ],
                  ),
                ),
                // Cuánto le queda: se pausa mientras se mantiene presionado.
                AnimatedBuilder(
                  animation: _left,
                  builder: (context, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: reduced ? 1 : _left.value,
                      child: Container(height: 3, color: tone.withValues(alpha: 0.7)),
                    ),
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
