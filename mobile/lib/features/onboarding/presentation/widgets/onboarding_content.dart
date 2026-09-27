import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

@immutable
class OnboardingSlide {
  const OnboardingSlide({required this.title, required this.body, required this.cta});

  final String title;
  final String body;
  final String cta;
}

/// Una historia en tres pasos: descubre, pide, recibe.
const onboardingSlides = [
  OnboardingSlide(
    title: 'Un barrio entero.\nA un toque.',
    body: 'Picanterías, bodegas, boticas y ese pan que se acaba temprano. Todo a pocos minutos.',
    cta: 'Siguiente',
  ),
  OnboardingSlide(
    title: 'Tu antojo tiene\nbuenas manos.',
    body: 'Detrás de cada pedido hay alguien con nombre: la señora del caldo, el panadero de la esquina.',
    cta: 'Siguiente',
  ),
  OnboardingSlide(
    title: 'La próxima parada:\ntu puerta.',
    body: 'En casa, en la chamba o en la plaza. Tú solo abre la puerta.',
    cta: 'Empezar a pedir',
  ),
];

/// Texto del paso. Cada línea se desplaza a distinta velocidad con el swipe
/// ([pageOffset]) y, en la primera apertura, entra escalonada ([animateIn]).
class OnboardingCopy extends StatelessWidget {
  const OnboardingCopy({
    required this.slide,
    required this.compact,
    this.pageOffset = 0,
    this.animateIn = false,
    super.key,
  });

  final OnboardingSlide slide;
  final bool compact;
  final double pageOffset;
  final bool animateIn;

  Widget _layer(int order, Widget child) {
    final offset = pageOffset.clamp(-1.0, 1.0);
    return Opacity(
      opacity: (1 - offset.abs() * 1.4).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(-offset * (24 + order * 16), 0),
        child: FadeSlideIn(
          enabled: animateIn,
          delay: Duration(milliseconds: 250 + order * 90),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _layer(
          0,
          Semantics(
            header: true,
            child: Text(slide.title, style: compact ? theme.textTheme.headlineMedium : theme.textTheme.displaySmall),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _layer(
          1,
          Text(slide.body, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
