import 'dart:async';

import 'package:chaski/features/auth/domain/value_objects/otp_code.dart';
import 'package:chaski/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:chaski/features/auth/presentation/providers/phone_auth_flow.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paso 2: el código de 6 dígitos. Verifica al completar la última casilla;
/// "Verificar" queda como acción explícita (deshabilitada hasta completar).
class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({this.onProfileRequired, super.key});

  static const name = 'otp';

  /// Qué hacer si el número no tiene cuenta. Por defecto se pide el nombre
  /// para crearla (app del cliente); Chaski Socios no crea cuentas.
  final void Function(BuildContext context)? onProfileRequired;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpKey = GlobalKey<AuthOtpFieldState>();
  String _code = '';
  Timer? _ticker;
  Duration _resendIn = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final at = ref.read(phoneAuthFlowProvider).canResendAt;
    final left = at == null ? Duration.zero : at.difference(DateTime.now());
    if (mounted) setState(() => _resendIn = left.isNegative ? Duration.zero : left);
  }

  Future<void> _verify(String raw) async {
    final code = OtpCode.create(raw).valueOrNull;
    if (code == null) return;
    final next = await ref.read(phoneAuthFlowProvider.notifier).verify(code);
    if (!mounted) return;
    switch (next) {
      case PhoneAuthStep.profile:
        final custom = widget.onProfileRequired;
        if (custom != null) {
          custom(context);
        } else {
          await context.pushNamed(ProfileSetupPage.name);
        }
      case PhoneAuthStep.code:
        // Código incorrecto: vibración y casillas limpias para reintentar.
        HapticFeedback.heavyImpact().ignore();
        _otpKey.currentState?.clear();
        setState(() => _code = '');
      case PhoneAuthStep.phone || null:
        break; // Sesión iniciada: el router redirige.
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(phoneAuthFlowProvider).phone;
    if (phone == null) return;
    final sent = await ref.read(phoneAuthFlowProvider.notifier).requestCode(phone);
    if (!mounted) return;
    _tick();
    if (sent) AppToast.show(context, 'Te enviamos un código nuevo.', kind: AppToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = ref.watch(phoneAuthFlowProvider);
    final phone = flow.phone?.value ?? '';
    final seconds = _resendIn.inSeconds;
    final length = flow.challenge?.codeLength ?? OtpCode.length;
    final complete = _code.length == length;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return AuthScaffold(
      showBack: true,
      action: AppButton(
        label: 'Verificar',
        loading: flow.loading,
        onPressed: complete && !flow.loading ? () => _verify(_code) : null,
      ),
      children: [
        AuthHeader(
          title: 'Escribe el código',
          subtitle: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Lo enviamos al ${formatPhone(phone)} · '),
              AuthLink(
                label: 'Cambiar',
                semanticLabel: 'Cambiar número',
                onTap: flow.loading ? null : () => context.pop(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthOtpField(
          key: _otpKey,
          length: length,
          enabled: !flow.loading,
          hasError: flow.error != null && flow.step == PhoneAuthStep.code,
          onChanged: (value) {
            setState(() => _code = value);
            if (flow.error != null) ref.read(phoneAuthFlowProvider.notifier).clearError();
          },
          onCompleted: _verify,
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSwitcher(
          duration: AppMotion.quick,
          child: seconds > 0
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
                            text: '0:${seconds.toString().padLeft(2, '0')}',
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
                    AuthLink(
                      label: 'Reenviar código',
                      onTap: flow.loading ? null : _resend,
                    ),
                  ],
                ),
        ),
        AnimatedFormError(error: flow.step == PhoneAuthStep.code ? flow.error : null),
      ],
    );
  }
}
