import 'package:chaski/core/config/app_config_provider.dart';
import 'package:chaski/core/domain/phone_number.dart';
import 'package:chaski/features/auth/presentation/pages/otp_page.dart';
import 'package:chaski/features/auth/presentation/providers/auth_demo.dart';
import 'package:chaski/features/auth/presentation/providers/phone_auth_flow.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_fields.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/utils/value_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paso 1 de la entrada: el celular. Sin contraseñas.
class PhoneEntryPage extends ConsumerStatefulWidget {
  const PhoneEntryPage({
    this.title = '¿Cuál es tu celular?',
    this.subtitle = 'Te mandamos un código por SMS. Sin contraseñas.',
    this.demoAccounts = const [AuthDemo.customer],
    super.key,
  });

  static const name = 'login';

  final String title;
  final String subtitle;

  /// Cuentas que el modo demo ofrece para entrar con un toque.
  final List<DemoAccount> demoAccounts;

  @override
  ConsumerState<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends ConsumerState<PhoneEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    final previous = ref.read(phoneAuthFlowProvider).phone;
    if (previous != null) _phone.text = previous.value;
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final phone = PhoneNumber.create(_phone.text).valueOrNull!;
    final sent = await ref.read(phoneAuthFlowProvider.notifier).requestCode(phone);
    if (sent && mounted) await context.pushNamed(OtpPage.name);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(phoneAuthFlowProvider);
    final demo = ref.watch(appEnvProvider).useFakeData;

    return AuthScaffold(
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(label: 'Enviarme el código', loading: flow.loading, onPressed: _submit),
          const SizedBox(height: AppSpacing.sm),
          const AuthLegalNote(),
        ],
      ),
      children: [
        AuthHeader(title: widget.title, subtitle: Text(widget.subtitle)),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: AuthPhoneField(
            controller: _phone,
            onSubmitted: (_) => _submit(),
            onChanged: (_) => ref.read(phoneAuthFlowProvider.notifier).clearError(),
            validator: (value) => PhoneNumber.create(value ?? '').failureOrNull?.message,
          ),
        ),
        AnimatedFormError(error: flow.step == PhoneAuthStep.phone ? flow.error : null),
        if (demo) ...[
          const SizedBox(height: AppSpacing.xl),
          for (final account in widget.demoAccounts) ...[
            _DemoHint(
              account: account,
              showLabel: widget.demoAccounts.length > 1,
              onUse: () async {
                _phone.text = account.phone;
                await _submit();
              },
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.account, required this.showLabel, required this.onUse});

  final DemoAccount account;
  final bool showLabel;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.card),
      child: Row(
        children: [
          Icon(Icons.science_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${showLabel ? '${account.label}: ' : 'Modo demo: '}usa ${PhoneNumber.displayOf(account.phone)} y el código ${AuthDemo.code}.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
          AppButton.ghost(label: 'Usar', onPressed: onUse, size: AppButtonSize.sm),
        ],
      ),
    );
  }
}
