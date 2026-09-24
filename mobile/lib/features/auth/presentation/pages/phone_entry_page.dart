import 'package:chaski/app/config/app_config_provider.dart';
import 'package:chaski/core/domain/phone_number.dart';
import 'package:chaski/features/auth/infrastructure/datasources/remote/fake_auth_remote_data_source.dart';
import 'package:chaski/features/auth/presentation/pages/otp_page.dart';
import 'package:chaski/features/auth/presentation/providers/phone_auth_flow.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/utils/value_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paso 1 de la entrada: el celular. Sin contraseñas.
class PhoneEntryPage extends ConsumerStatefulWidget {
  const PhoneEntryPage({super.key});

  static const name = 'login';

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
        const AuthHeader(
          title: '¿Cuál es tu celular?',
          subtitle: Text('Te mandamos un código por SMS. Sin contraseñas.'),
        ),
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
          _DemoHint(
            onUse: () async {
              _phone.text = FakeAuthRemoteDataSource.demoPhone;
              await _submit();
            },
          ),
        ],
      ],
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.onUse});

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
              'Modo demo: usa ${formatPhone(FakeAuthRemoteDataSource.demoPhone)} y el código ${FakeAuthRemoteDataSource.demoCode}.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
          AppButton.ghost(label: 'Usar', onPressed: onUse, size: AppButtonSize.sm),
        ],
      ),
    );
  }
}
