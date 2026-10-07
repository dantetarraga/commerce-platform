import 'package:chaski/core/domain/email_address.dart';
import 'package:chaski/core/domain/phone_number.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/utils/value_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Nombre y correo de la cuenta. El celular no se cambia aquí: requiere verificar el número nuevo.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  static const name = 'edit-profile';

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  var _saving = false;
  String? _emailError;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authSessionProvider).value;
    _firstName = TextEditingController(text: user?.firstName);
    _lastName = TextEditingController(text: user?.lastName);
    _email = TextEditingController(text: user?.email?.value);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  static String? _nameError(String? value) => PersonName.create(value ?? '').failureOrNull?.message;

  /// Vacío está bien: el correo es opcional.
  static String? _emailFormatError(String? value) =>
      (value ?? '').trim().isEmpty ? null : EmailAddress.create(value!).failureOrNull?.message;

  Future<void> _save() async {
    setState(() => _emailError = _error = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final session = ref.read(authSessionProvider.notifier);
    final email = _email.text.trim();
    final result = await ref
        .read(updateProfileProvider)
        .call(
          firstName: PersonName.create(_firstName.text).valueOrNull!,
          lastName: PersonName.create(_lastName.text).valueOrNull!,
          email: email.isEmpty ? null : EmailAddress.create(email).valueOrNull,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        AppToast.show(context, 'Listo, guardamos tus datos.');
        // Primero se cierra: actualizar la sesión refresca el router, que si no volvería a abrir esta pantalla.
        context.pop();
        session.userUpdated(value);
      case Err(failure: BusinessFailure(code: 'EMAIL_ALREADY_EXISTS', :final message)):
        setState(() => _emailError = message);
      case Err(failure: ValidationFailure(:final fieldErrors, :final message)):
        setState(() {
          _emailError = fieldErrors['email'];
          _error = _emailError == null ? message : null;
        });
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(authSessionProvider.select((s) => s.value?.phone.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Tus datos')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
            children: [
              AppInput(
                label: 'Nombre',
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                validator: _nameError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'Apellido',
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                validator: _nameError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'Correo (opcional)',
                controller: _email,
                hint: 'Para enviarte tus comprobantes',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                errorText: _emailError,
                validator: _emailFormatError,
                onSubmitted: (_) => _save(),
              ),
              if (phone != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Celular', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '+51 ${PhoneNumber.displayOf(phone)} · para cambiarlo, escríbenos.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.md),
                AppInlineNotice(message: error, kind: AppNoticeKind.error),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Guardar', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
