import 'dart:math' as math;

import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/legal/legal_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Pantallas de entrada: barra mínima (atrás o la marca), contenido
/// desplazable y la acción principal fija abajo (sube con el teclado).
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
                              child: BrandLogo(size: 28),
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

/// Título grande y una línea de apoyo atenuada.
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

/// Texto en color primario que actúa como enlace, con área táctil de 48.
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

/// Error del envío (código incorrecto, sin red…): entra con una sacudida corta
/// en vez de empujar el formulario de golpe. `error == null` no ocupa espacio.
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
                child: _Shake(enabled: !reduced, child: AppInlineNotice.fromError(error)),
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
      duration: AppMotion.shake,
      // Oscilación amortiguada: 3 vaivenes que se apagan.
      builder: (context, t, child) => Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 6 * (1 - t), 0), child: child),
      child: child,
    );
  }
}

/// "Al continuar aceptas los términos y la privacidad." con los enlaces resaltados.
class AuthLegalNote extends StatefulWidget {
  const AuthLegalNote({super.key});

  @override
  State<AuthLegalNote> createState() => _AuthLegalNoteState();
}

class _AuthLegalNoteState extends State<AuthLegalNote> {
  late final _terms = TapGestureRecognizer()..onTap = () => LegalPage.open(context, LegalDocument.terms);
  late final _privacy = TapGestureRecognizer()..onTap = () => LegalPage.open(context, LegalDocument.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700);
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Al continuar aceptas los '),
          TextSpan(text: 'términos', style: link, recognizer: _terms, semanticsLabel: 'Términos y condiciones'),
          const TextSpan(text: ' y la '),
          TextSpan(text: 'privacidad', style: link, recognizer: _privacy, semanticsLabel: 'Política de privacidad'),
          const TextSpan(text: ' de $brandName.'),
        ],
      ),
      style: theme.textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}
