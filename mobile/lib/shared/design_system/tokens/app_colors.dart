import 'package:flutter/material.dart';

/// Paleta Chaski · "Cobalto".
///
/// El cobalto es el único color que manda: acción principal, lo seleccionado y
/// la promo. La lima solo celebra (ofertas, cupones, logros) y siempre va como
/// relleno con texto tinta encima, nunca como texto. El fondo es blanco limpio
/// y los grises son neutros, sin tinte beige.
///
/// Los widgets no usan esta clase directamente: leen `ColorScheme` y
/// [ChaskiColors] (vía `context.chaski`), que ya resuelven claro/oscuro.
abstract final class AppColors {
  // Marca
  static const cobalto = Color(0xFF1D5BFF);
  static const cobalto700 = Color(0xFF1240C2);
  static const cobalto50 = Color(0xFFE6EDFF);
  static const cobalto300 = Color(0xFF7C9DFF); // cobalto sobre fondos oscuros
  static const cobaltoNight = Color(0xFF172245); // contenedor cobalto en oscuro
  static const lima = Color(0xFFC5F25A);
  static const limaSoft = Color(0xFFF2FBDB);

  // Neutros claros
  static const blanco = Color(0xFFFFFFFF);
  static const gris = Color(0xFFF4F4F6); // bloques agrupados, campos
  static const grisAlto = Color(0xFFE9E9EE);
  static const tinta = Color(0xFF16151C);
  static const piedra = Color(0xFF6A6975);
  static const linea = Color(0xFFECEBF0);

  // Neutros oscuros
  static const noche = Color(0xFF0E0E12);
  static const nocheSurface = Color(0xFF18181E);
  static const nocheRaised = Color(0xFF202027);
  static const nocheHigh = Color(0xFF2B2B34);
  static const nocheLinea = Color(0xFF2A2A32);
  static const nocheTexto = Color(0xFFF3F2F6);
  static const nochePiedra = Color(0xFFA4A3AE);

  // Estados
  static const exito = Color(0xFF12805C); // abierto · envío gratis · descuento
  static const exito300 = Color(0xFF4FD1A0);
  static const peligro = Color(0xFFC0392B); // error · eliminar · cerrado
  static const peligro300 = Color(0xFFFF8A7A);
  static const rating = Color(0xFFE8A317);
}

/// Colores semánticos que `ColorScheme` no cubre, resueltos por tema.
@immutable
class ChaskiColors extends ThemeExtension<ChaskiColors> {
  const ChaskiColors({
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.danger,
    required this.raised,
    required this.thread,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.onPhoto,
    required this.scrim,
    required this.rating,
  });

  static const light = ChaskiColors(
    accent: AppColors.lima,
    onAccent: AppColors.tinta,
    accentSoft: AppColors.limaSoft,
    success: AppColors.exito,
    danger: AppColors.peligro,
    raised: AppColors.gris,
    thread: AppColors.cobalto,
    shimmerBase: AppColors.gris,
    shimmerHighlight: Color(0xFFFAFAFB),
    onPhoto: AppColors.blanco,
    scrim: Color(0x7316151C),
    rating: AppColors.rating,
  );

  static const dark = ChaskiColors(
    accent: AppColors.lima,
    onAccent: AppColors.tinta,
    accentSoft: Color(0xFF27301A),
    success: AppColors.exito300,
    danger: AppColors.peligro300,
    raised: AppColors.nocheRaised,
    thread: AppColors.cobalto300,
    shimmerBase: AppColors.nocheRaised,
    shimmerHighlight: AppColors.nocheHigh,
    onPhoto: AppColors.blanco,
    scrim: Color(0x99000000),
    rating: AppColors.rating,
  );

  /// Lima: cintas de oferta, cupones, logros. Solo relleno.
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color success;
  final Color danger;

  /// Bloques agrupados sin borde (campos, chips, miniaturas vacías).
  final Color raised;

  /// Color de líneas de progreso, rutas e ilustraciones.
  final Color thread;
  final Color shimmerBase;
  final Color shimmerHighlight;

  /// Texto e íconos sobre fotografía.
  final Color onPhoto;

  /// Velo detrás de hojas y sobre fotos.
  final Color scrim;

  /// Estrella de calificación.
  final Color rating;

  @override
  ChaskiColors copyWith({
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? danger,
    Color? raised,
    Color? thread,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? onPhoto,
    Color? scrim,
    Color? rating,
  }) => ChaskiColors(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentSoft: accentSoft ?? this.accentSoft,
    success: success ?? this.success,
    danger: danger ?? this.danger,
    raised: raised ?? this.raised,
    thread: thread ?? this.thread,
    shimmerBase: shimmerBase ?? this.shimmerBase,
    shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    onPhoto: onPhoto ?? this.onPhoto,
    scrim: scrim ?? this.scrim,
    rating: rating ?? this.rating,
  );

  @override
  ChaskiColors lerp(ChaskiColors? other, double t) {
    if (other == null) return this;
    return ChaskiColors(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      thread: Color.lerp(thread, other.thread, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      onPhoto: Color.lerp(onPhoto, other.onPhoto, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
    );
  }
}

extension ChaskiColorsContext on BuildContext {
  /// Colores semánticos de Chaski para el tema actual.
  ChaskiColors get chaski => Theme.of(this).extension<ChaskiColors>() ?? ChaskiColors.light;
}
