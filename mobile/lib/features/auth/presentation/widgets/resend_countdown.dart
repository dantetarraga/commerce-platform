import 'dart:async';

import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// "¿No llegó? Reenviar en 0:42" que pasa a "Reenviar código" en cero.
/// Solo este widget se reconstruye cada segundo y el timer se detiene en 0.
class ResendCountdown extends StatefulWidget {
  const ResendCountdown({required this.canResendAt, required this.onResend, super.key});

  /// Desde cuándo se puede pedir otro código (null = ya se puede).
  final DateTime? canResendAt;
  final VoidCallback? onResend;

  @override
  State<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends State<ResendCountdown> {
  Timer? _timer;
  var _seconds = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(ResendCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canResendAt != widget.canResendAt) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    final at = widget.canResendAt;
    final left = at == null ? Duration.zero : at.difference(DateTime.now());
    // Redondea hacia arriba: "0:01" se ve hasta que de verdad se puede.
    _seconds = left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
    if (_seconds == 0) return;
    // Cuenta con el timer (no con el reloj) para que avance igual en pruebas.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds--);
      if (_seconds <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return AnimatedSwitcher(
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
      child: _seconds > 0
          ? ConstrainedBox(
              key: const ValueKey('wait'),
              constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '¿No llegó? Reenviar en '),
                      TextSpan(
                        text: Formatters.minutesSeconds(_seconds),
                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  style: muted?.copyWith(fontFeatures: AppTypography.tabularFigures),
                ),
              ),
            )
          : Wrap(
              key: const ValueKey('resend'),
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('¿No llegó? ', style: muted),
                AuthLink(label: 'Reenviar código', onTap: widget.onResend),
              ],
            ),
    );
  }
}
