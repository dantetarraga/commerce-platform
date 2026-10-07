import 'package:flutter/widgets.dart';

/// Píxeles que crece un texto de [base] px con la escala del sistema (tope [max]),
/// para que las alturas fijas crezcan con la letra.
double textScaleExtra(BuildContext context, {double base = 16, double max = 24}) =>
    (MediaQuery.textScalerOf(context).scale(base) - base).clamp(0.0, max);

/// `true` si un texto de [base] px ya se ve de [limit] px o más (letra grande):
/// conviene apilar en vez de poner lado a lado.
bool isLargeText(BuildContext context, {double base = 16, double limit = 20}) =>
    MediaQuery.textScalerOf(context).scale(base) >= limit;
