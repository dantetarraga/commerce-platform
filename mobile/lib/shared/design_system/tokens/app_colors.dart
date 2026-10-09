import 'package:flutter/material.dart';

/// Terracota: crema cálida, terracota de marca y verde hierba de acento.
abstract final class AppColors {
  static const terracota = Color(0xFFB84A2B);
  static const terracota700 = Color(0xFF8F3920);
  static const terracota50 = Color(0xFFF7E6DC); // portadas y fondos de marca suaves
  static const terracota300 = Color(0xFFF09A7B); // terracota sobre fondos oscuros
  static const terracotaNight = Color(0xFF3A1E16); // contenedor terracota en oscuro
  static const hierba = Color(0xFF4E7A40); // ofertas, en vivo, envío gratis. Texto blanco encima
  static const hierbaSoft = Color(0xFFE6EFE0);
  static const ocre = Color(0xFFE0A15A); // sombra del logo y pedido de Socios
  static const hierba300 = Color(0xFF8CC07A); // hierba sobre fondos oscuros

  static const papel = Color(0xFFFBF7F2); // fondo crema
  static const blanco = Color(0xFFFFFFFF);
  static const gris = Color(0xFFF3ECE3); // bloques agrupados, campos
  static const grisAlto = Color(0xFFEADFD3);
  static const tinta = Color(0xFF2A1A14); // texto principal, café muy oscuro
  static const piedra = Color(0xFF6E5F56);
  static const linea = Color(0xFFEDE3D8);

  static const noche = Color(0xFF140F0D);
  static const nocheSurface = Color(0xFF1C1613);
  static const nocheRaised = Color(0xFF261E1A);
  static const nocheHigh = Color(0xFF312722);
  static const nocheLinea = Color(0xFF33281F);
  static const nocheTexto = Color(0xFFF6EFEA);
  static const nochePiedra = Color(0xFFB3A59C);

  static const exito = Color(0xFF3F7A3A); // abierto · envío gratis · descuento
  static const exito300 = Color(0xFF8CC07A);
  static const peligro = Color(0xFFB3261E); // error · eliminar · cerrado
  static const peligro300 = Color(0xFFFF8A7A);
  static const rating = Color(0xFFB84A2B);

  /// Texto secundario claro sobre fotografía oscurecida o sobre hierba.
  static const onPhotoMuted = Color(0xFFF1E6DE);

  /// Velo de tinta con la opacidad [alpha] (0–1): degradados sobre fotos, sombras.
  static Color inkOverlay(double alpha) => tinta.withValues(alpha: alpha);
}

/// Colores semánticos que `ColorScheme` no cubre, resueltos por tema.
@immutable
class ApamuyColors extends ThemeExtension<ApamuyColors> {
  const ApamuyColors({
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
    required this.card,
    required this.onPhotoMuted,
  });

  static const light = ApamuyColors(
    accent: AppColors.hierba,
    onAccent: AppColors.blanco,
    accentSoft: AppColors.hierbaSoft,
    success: AppColors.exito,
    danger: AppColors.peligro,
    raised: AppColors.gris,
    thread: AppColors.terracota,
    shimmerBase: AppColors.gris,
    shimmerHighlight: Color(0xFFFDFAF6),
    onPhoto: AppColors.blanco,
    scrim: Color(0x732A1A14),
    rating: AppColors.rating,
    card: AppColors.blanco,
    onPhotoMuted: AppColors.onPhotoMuted,
  );

  static const dark = ApamuyColors(
    accent: AppColors.hierba300,
    onAccent: AppColors.noche,
    accentSoft: Color(0xFF22301D),
    success: AppColors.exito300,
    danger: AppColors.peligro300,
    raised: AppColors.nocheRaised,
    thread: AppColors.terracota300,
    shimmerBase: AppColors.nocheRaised,
    shimmerHighlight: AppColors.nocheHigh,
    onPhoto: AppColors.blanco,
    scrim: Color(0x99000000),
    rating: AppColors.terracota300,
    card: AppColors.nocheRaised,
    onPhotoMuted: AppColors.onPhotoMuted,
  );

  /// Hierba: cintas de oferta, envío gratis, lo que pasa ahora.
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

  /// Fondo de tarjeta que se despega del fondo: blanco en claro, [raised] en oscuro.
  final Color card;

  /// Texto secundario claro sobre fotografía (bajada de portadas).
  final Color onPhotoMuted;

  @override
  ApamuyColors copyWith({
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
    Color? card,
    Color? onPhotoMuted,
  }) => ApamuyColors(
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
    card: card ?? this.card,
    onPhotoMuted: onPhotoMuted ?? this.onPhotoMuted,
  );

  @override
  ApamuyColors lerp(ApamuyColors? other, double t) {
    if (other == null) return this;
    return ApamuyColors(
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
      card: Color.lerp(card, other.card, t)!,
      onPhotoMuted: Color.lerp(onPhotoMuted, other.onPhotoMuted, t)!,
    );
  }
}

extension ApamuyColorsContext on BuildContext {
  ApamuyColors get apamuy => Theme.of(this).extension<ApamuyColors>() ?? ApamuyColors.light;
}
