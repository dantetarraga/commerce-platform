import 'dart:math' as math;

import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mensaje de error del envío (código incorrecto, sin red, etc.).
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final danger = context.chaski.danger;
    final message = switch (error) {
      NetworkFailure() => 'Se cortó el hilo. Revisa tu conexión y vuelve a intentarlo.',
      Failure(:final message) => message,
      _ => const ServerFailure().message,
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: danger.withValues(alpha: 0.08),
          borderRadius: AppRadius.tile,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: danger, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: danger))),
          ],
        ),
      ),
    );
  }
}

/// Aparece/desaparece con fade + tamaño y una sacudida corta, en vez de empujar
/// el formulario de golpe. `error == null` no ocupa espacio.
class AnimatedFormError extends StatelessWidget {
  const AnimatedFormError({required this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotionOf(context);
    final error = this.error;
    return AnimatedSize(
      duration: reduced ? Duration.zero : AppMotion.base,
      curve: AppMotion.arrive,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: reduced ? Duration.zero : AppMotion.quick,
        child: error == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(error),
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: _Shake(enabled: !reduced, child: FormErrorBanner(error: error)),
              ),
      ),
    );
  }
}

class _Shake extends StatelessWidget {
  const _Shake({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) =>
          // Oscilación amortiguada: 3 vaivenes que se apagan.
          Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 6 * (1 - t), 0), child: child),
      child: child,
    );
  }
}

/// Estructura común de las pantallas de entrada: barra superior mínima (atrás o
/// la marca), contenido desplazable y la acción principal fija abajo (sube con
/// el teclado).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.children, required this.action, this.showBack = false, super.key});

  final List<Widget> children;
  final Widget action;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxs, AppSpacing.xxs, AppSpacing.gutter, 0),
                  child: SizedBox(
                    height: AppSpacing.minTouch,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: showBack
                          ? const BackButton()
                          : const Padding(
                              padding: EdgeInsets.only(left: AppSpacing.md),
                              child: ChaskiLogo(size: 28),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
                  child: action,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Título grande en Outfit + una línea de apoyo en gris.
class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, required this.subtitle, super.key});

  final String title;

  /// Texto o una fila con enlaces (p. ej. "Lo enviamos al … · Cambiar").
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: theme.textTheme.headlineMedium)),
        const SizedBox(height: AppSpacing.xs),
        DefaultTextStyle.merge(
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          child: subtitle,
        ),
      ],
    );
  }
}

/// Texto cobalto que actúa como enlace, con área táctil de 48.
class AuthLink extends StatelessWidget {
  const AuthLink({required this.label, required this.onTap, this.semanticLabel, super.key});

  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.tile,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Celular peruano: prefijo "🇵🇪 +51" separado por una línea, relleno gris
/// del tema (borde cobalto al enfocar), 9 dígitos.
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

/// Código de [length] dígitos en casillas grises; la que toca escribir lleva
/// borde cobalto. Un único campo invisible recibe el teclado (admite pegar el
/// código completo y el autocompletado por SMS).
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

    return Semantics(
      label: 'Código de verificación de ${widget.length} dígitos',
      value: code.isEmpty ? null : '${code.length} de ${widget.length} escritos',
      textField: true,
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

/// "Al continuar aceptas los términos y la privacidad." con los enlaces en cobalto.
class AuthLegalNote extends StatelessWidget {
  const AuthLegalNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700);
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Al continuar aceptas los '),
          TextSpan(text: 'términos', style: link),
          const TextSpan(text: ' y la '),
          TextSpan(text: 'privacidad', style: link),
          const TextSpan(text: ' de Chaski.'),
        ],
      ),
      style: theme.textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}

/// "984 123 456" para mostrar el número al usuario.
String formatPhone(String digits) =>
    digits.length == 9 ? '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}' : digits;
