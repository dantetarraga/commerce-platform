import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Celular peruano: prefijo "🇵🇪 +51" separado por una línea y 9 dígitos.
class AuthPhoneField extends StatelessWidget {
  const AuthPhoneField({
    required this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digits = theme.textTheme.titleMedium?.copyWith(letterSpacing: 1.2, fontFeatures: AppTypography.tabularFigures);
    return Semantics(
      label: 'Tu celular',
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        maxLength: 9,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: digits,
        decoration: InputDecoration(
          hintText: '9•• ••• •••',
          counterText: '',
          errorMaxLines: 2,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(child: Text('🇵🇪 +51', style: digits?.copyWith(letterSpacing: 0))),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(height: 24, child: VerticalDivider(width: 1, thickness: 1, color: scheme.outline)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Código de [length] dígitos en casillas. Un único campo invisible recibe el
/// teclado (admite pegar el código y el autocompletado por SMS).
class AuthOtpField extends StatefulWidget {
  const AuthOtpField({
    required this.onCompleted,
    this.length = 6,
    this.onChanged,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
    super.key,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  @override
  State<AuthOtpField> createState() => AuthOtpFieldState();
}

class AuthOtpFieldState extends State<AuthOtpField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// Borra lo ingresado (tras un código incorrecto) y vuelve a enfocar.
  void clear() {
    _controller.clear();
    _focus.requestFocus();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    final code = _controller.text;
    final reduced = reduceMotionOf(context);

    // Un solo nodo para el lector: el campo real está oculto (opacidad 0).
    return Semantics(
      label: 'Código de verificación de ${widget.length} dígitos',
      value: code.isEmpty ? null : '${code.length} de ${widget.length} escritos',
      textField: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? _focus.requestFocus : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focus.requestFocus,
        child: Stack(
          children: [
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 58,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: widget.length,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _changed,
                  showCursor: false,
                  decoration: const InputDecoration(counterText: '', border: InputBorder.none, filled: false),
                ),
              ),
            ),
            IgnorePointer(
              child: ExcludeSemantics(
                child: ListenableBuilder(
                  listenable: _focus,
                  builder: (context, _) => Row(
                    children: [
                      for (var i = 0; i < widget.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: AnimatedContainer(
                            duration: reduced ? Duration.zero : AppMotion.quick,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: chaski.raised,
                              borderRadius: AppRadius.button,
                              border: Border.all(
                                width: 2,
                                color: widget.hasError
                                    ? chaski.danger
                                    : (_focus.hasFocus && i == code.length.clamp(0, widget.length - 1))
                                    ? scheme.primary
                                    : scheme.primary.withValues(alpha: 0),
                              ),
                            ),
                            child: Text(
                              i < code.length ? code[i] : '',
                              style: theme.textTheme.headlineSmall?.copyWith(fontFeatures: AppTypography.tabularFigures),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
