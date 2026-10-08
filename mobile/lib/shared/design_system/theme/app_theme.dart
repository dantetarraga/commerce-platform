import 'package:apamuy/shared/design_system/theme/page_transitions.dart';
import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:apamuy/shared/design_system/tokens/app_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Tema de Apamuy claro/oscuro. En oscuro no se invierte: la terracota se aclara y la
/// elevación se expresa con superficies más claras, no con sombras.
abstract final class AppTheme {
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.terracota,
      onPrimary: AppColors.blanco,
      primaryContainer: AppColors.terracota50,
      onPrimaryContainer: AppColors.terracota700,
      secondary: AppColors.hierba,
      onSecondary: AppColors.blanco,
      secondaryContainer: AppColors.hierbaSoft,
      onSecondaryContainer: Color(0xFF2E4A26),
      tertiary: AppColors.exito,
      onTertiary: AppColors.blanco,
      error: AppColors.peligro,
      onError: AppColors.blanco,
      surface: AppColors.papel,
      onSurface: AppColors.tinta,
      onSurfaceVariant: AppColors.piedra,
      surfaceContainerLowest: AppColors.blanco,
      surfaceContainerLow: Color(0xFFFDFAF6),
      surfaceContainer: AppColors.gris,
      surfaceContainerHigh: AppColors.grisAlto,
      surfaceContainerHighest: Color(0xFFE2D5C7),
      outline: Color(0xFFD6C8BA),
      outlineVariant: AppColors.linea,
      inverseSurface: AppColors.tinta,
      onInverseSurface: AppColors.blanco,
      inversePrimary: AppColors.terracota300,
    ),
    scaffoldBackground: AppColors.papel,
    apamuy: ApamuyColors.light,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.terracota300,
      onPrimary: Color(0xFF2A1208),
      primaryContainer: AppColors.terracotaNight,
      onPrimaryContainer: Color(0xFFFFDCCF),
      secondary: AppColors.hierba300,
      onSecondary: AppColors.noche,
      secondaryContainer: Color(0xFF22301D),
      onSecondaryContainer: Color(0xFFD5EBCB),
      tertiary: AppColors.exito300,
      onTertiary: AppColors.noche,
      error: AppColors.peligro300,
      onError: AppColors.noche,
      surface: AppColors.nocheSurface,
      onSurface: AppColors.nocheTexto,
      onSurfaceVariant: AppColors.nochePiedra,
      surfaceContainerLowest: AppColors.noche,
      surfaceContainerLow: AppColors.noche,
      surfaceContainer: AppColors.nocheRaised,
      surfaceContainerHigh: AppColors.nocheHigh,
      surfaceContainerHighest: Color(0xFF3E322B),
      outline: Color(0xFF55463D),
      outlineVariant: AppColors.nocheLinea,
      inverseSurface: AppColors.nocheTexto,
      onInverseSurface: AppColors.noche,
      inversePrimary: AppColors.terracota,
    ),
    scaffoldBackground: AppColors.noche,
    apamuy: ApamuyColors.dark,
  );

  static ThemeData _build(ColorScheme scheme, {required Color scaffoldBackground, required ApamuyColors apamuy}) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: AppTypography.ui);
    final textTheme = AppTypography.textTheme(scheme.onSurface, scheme.onSurfaceVariant);

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      extensions: [apamuy],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          foregroundColor: scheme.onSurface,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: apamuy.raised,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
        border: const OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: apamuy.raised,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        titleTextStyle: textTheme.headlineSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: apamuy.raised,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadius.tile),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontSize: 11.5,
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: apamuy.raised),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.tile),
      ),
      // Push a detalle: en Android la pantalla sube como tarjeta con la esquina de
      // salida; en iOS se mantiene el deslizamiento con gesto de regreso.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: RisingCardPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    );
  }
}
