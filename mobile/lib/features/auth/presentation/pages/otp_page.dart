import 'package:chaski/core/domain/phone_number.dart';
import 'package:chaski/features/auth/domain/value_objects/otp_code.dart';
import 'package:chaski/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:chaski/features/auth/presentation/providers/phone_auth_flow.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_fields.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:chaski/features/auth/presentation/widgets/resend_countdown.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paso 2: el código. Verifica al completar la última casilla; "Verificar"
/// queda como acción explícita.
class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({this.onProfileRequired, super.key});

  static const name = 'otp';

  /// Qué hacer si el número no tiene cuenta. Por defecto se pide el nombre
  /// para crearla; Apamuy Socios no crea cuentas.
  final void Function(BuildContext context)? onProfileRequired;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpKey = GlobalKey<AuthOtpFieldState>();
  String _code = '';

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
    if (sent) AppToast.show(context, 'Te enviamos un código nuevo.', kind: AppToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(phoneAuthFlowProvider);
    final phone = flow.phone?.value ?? '';
    final length = flow.challenge?.codeLength ?? OtpCode.length;
    final complete = _code.length == length;

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
              Text('Lo enviamos al ${PhoneNumber.displayOf(phone)} · '),
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
        ResendCountdown(
          canResendAt: flow.canResendAt,
          onResend: flow.loading ? null : _resend,
        ),
        AnimatedFormError(error: flow.step == PhoneAuthStep.code ? flow.error : null),
      ],
    );
  }
}
