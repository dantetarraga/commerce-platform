import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/app_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Tema Chaski claro/oscuro. En oscuro no se invierte: el cobalto se aclara y la
/// elevación se expresa con superficies más claras, no con sombras.
abstract final class AppTheme {
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.cobalto,
      onPrimary: AppColors.blanco,
      primaryContainer: AppColors.cobalto50,
      onPrimaryContainer: AppColors.cobalto700,
      secondary: AppColors.lima,
      onSecondary: AppColors.tinta,
      secondaryContainer: AppColors.limaSoft,
      onSecondaryContainer: AppColors.tinta,
      tertiary: AppColors.exito,
      onTertiary: AppColors.blanco,
      error: AppColors.peligro,
      onError: AppColors.blanco,
      surface: AppColors.blanco,
      onSurface: AppColors.tinta,
      onSurfaceVariant: AppColors.piedra,
      surfaceContainerLowest: AppColors.blanco,
      surfaceContainerLow: Color(0xFFFAFAFB),
      surfaceContainer: AppColors.gris,
      surfaceContainerHigh: AppColors.grisAlto,
      surfaceContainerHighest: Color(0xFFDDDDE3),
      outline: Color(0xFFCFCED6),
      outlineVariant: AppColors.linea,
      inverseSurface: AppColors.tinta,
      onInverseSurface: AppColors.blanco,
      inversePrimary: AppColors.cobalto300,
    ),
    scaffoldBackground: AppColors.blanco,
    chaski: ChaskiColors.light,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.cobalto300,
      onPrimary: Color(0xFF0A1233),
      primaryContainer: AppColors.cobaltoNight,
      onPrimaryContainer: Color(0xFFD6E0FF),
      secondary: AppColors.lima,
      onSecondary: AppColors.tinta,
      secondaryContainer: Color(0xFF27301A),
      onSecondaryContainer: Color(0xFFE4F8B8),
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
      surfaceContainerHighest: Color(0xFF383844),
      outline: Color(0xFF4A4A56),
      outlineVariant: AppColors.nocheLinea,
      inverseSurface: AppColors.nocheTexto,
      onInverseSurface: AppColors.noche,
      inversePrimary: AppColors.cobalto,
    ),
    scaffoldBackground: AppColors.noche,
    chaski: ChaskiColors.dark,
  );

  static ThemeData _build(ColorScheme scheme, {required Color scaffoldBackground, required ChaskiColors chaski}) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: AppTypography.ui);
    final textTheme = AppTypography.textTheme(scheme.onSurface, scheme.onSurfaceVariant);

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      extensions: [chaski],
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
        fillColor: chaski.raised,
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
        backgroundColor: chaski.raised,
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
        indicatorColor: chaski.raised,
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
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: chaski.raised),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.tile),
      ),
      // Push a detalle: nativo en cada plataforma (fade-forwards en Android,
      // deslizamiento con gesto de regreso en iOS).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    );
  }
}
