import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppInputVariant {
  text,

  /// Celular peruano: prefijo +51 fijo, teclado numérico, 9 dígitos.
  phone,

  /// Nota libre multilínea con contador (indicaciones para el negocio).
  note,
}

/// Campo de texto con la etiqueta fija arriba (no flotante): se lee igual con
/// o sin contenido y funciona mejor con texto grande.
class AppInput extends StatelessWidget {
  const AppInput({
    required this.label,
    this.controller,
    this.variant = AppInputVariant.text,
    this.hint,
    this.helper,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
    this.focusNode,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final AppInputVariant variant;
  final String? hint;
  final String? helper;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final IconData? prefixIcon;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = variant == AppInputVariant.phone;
    final isNote = variant == AppInputVariant.note;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(label, style: theme.textTheme.labelLarge),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          autofocus: autofocus,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction ?? (isNote ? TextInputAction.newline : TextInputAction.next),
          keyboardType: keyboardType ?? (isPhone ? TextInputType.phone : (isNote ? TextInputType.multiline : null)),
          autofillHints: autofillHints ?? (isPhone ? const [AutofillHints.telephoneNumberNational] : null),
          maxLength: maxLength ?? (isPhone ? 9 : null),
          maxLines: isNote ? 3 : 1,
          minLines: isNote ? 2 : 1,
          inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: isPhone
              ? theme.textTheme.titleMedium?.copyWith(letterSpacing: 1.2, fontFeatures: const [FontFeature.tabularFigures()])
              : theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            errorText: errorText,
            errorMaxLines: 2,
            counterText: isNote ? null : '',
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            prefix: isPhone
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Text('+51', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Código de verificación de [length] dígitos en casillas separadas.
/// Admite pegar el código completo y autocompletado por SMS.
class AppOtpField extends StatefulWidget {
  const AppOtpField({
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
  State<AppOtpField> createState() => AppOtpFieldState();
}

class AppOtpFieldState extends State<AppOtpField> {
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

    // Un único TextField invisible recibe el teclado; las casillas solo pintan.
    return Semantics(
      label: 'Código de verificación de ${widget.length} dígitos',
      textField: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focus.requestFocus,
        child: Stack(
          children: [
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 56,
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
              child: ListenableBuilder(
                listenable: _focus,
                builder: (context, _) => Row(
                  children: [
                    for (var i = 0; i < widget.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AnimatedContainer(
                          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: const BorderRadius.all(AppRadius.md),
                            border: Border.all(
                              width: 1.8,
                              color: widget.hasError
                                  ? chaski.danger
                                  : (_focus.hasFocus && i == code.length.clamp(0, widget.length - 1))
                                  ? scheme.primary
                                  : (i < code.length ? scheme.primary.withValues(alpha: 0.4) : scheme.outlineVariant),
                            ),
                          ),
                          child: Text(
                            i < code.length ? code[i] : '',
                            style: theme.textTheme.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
