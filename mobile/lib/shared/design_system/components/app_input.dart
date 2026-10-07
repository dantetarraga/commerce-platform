import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
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
