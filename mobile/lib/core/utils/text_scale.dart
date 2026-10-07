import 'package:flutter/widgets.dart';

/// Píxeles que crece un texto de [base] px con la escala de texto del sistema,
/// con tope [max]. Sirve para que las alturas fijas (portadas, filas de
/// categorías) crezcan con la letra: `268 + textScaleExtra(context, max: 30) * 7`.
double textScaleExtra(BuildContext context, {double base = 16, double max = 24}) =>
    (MediaQuery.textScalerOf(context).scale(base) - base).clamp(0.0, max);

/// `true` si un texto de [base] px ya se ve de [limit] px o más: letra grande
/// del sistema, donde conviene apilar en vez de poner lado a lado o esconder
/// adornos.
bool isLargeText(BuildContext context, {double base = 16, double limit = 20}) =>
    MediaQuery.textScalerOf(context).scale(base) >= limit;
