import 'package:chaski/features/auth/domain/value_objects/person_name.dart';
import 'package:chaski/features/auth/presentation/providers/phone_auth_flow.dart';
import 'package:chaski/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/utils/value_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paso 3 (solo números nuevos): el nombre. Es todo lo que pedimos.
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  static const name = 'profile-setup';

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Al crear la cuenta, el router redirige a Cerca.
    await ref
        .read(phoneAuthFlowProvider.notifier)
        .completeProfile(
          firstName: PersonName.create(_firstName.text).valueOrNull!,
          lastName: PersonName.create(_lastName.text).valueOrNull!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(phoneAuthFlowProvider);

    return AuthScaffold(
      showBack: true,
      action: AppButton(label: 'Empezar a pedir', loading: flow.loading, onPressed: _submit),
      children: [
        const AuthHeader(
          title: '¿Cómo te llamamos?',
          subtitle: Text('Así te saludarán en el negocio y quien te lleve el pedido.'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                AppInput(
                  label: 'Nombre',
                  controller: _firstName,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  validator: (v) => PersonName.create(v ?? '').failureOrNull?.message,
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: 'Apellido',
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.familyName],
                  onSubmitted: (_) => _submit(),
                  validator: (v) => PersonName.create(v ?? '').failureOrNull?.message,
                ),
              ],
            ),
          ),
        ),
        AnimatedFormError(error: flow.step == PhoneAuthStep.profile ? flow.error : null),
      ],
    );
  }
}
