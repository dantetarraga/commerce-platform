import 'package:chaski/shared/design_system/theme/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Lo común del `MaterialApp.router` de las dos apps (cliente y Apamuy
/// Socios): temas claro/oscuro, idioma es-PE con sus traducciones de Material
/// y el scroll que acepta mouse y trackpad.
///
/// ```dart
/// return AppMaterialDefaults.router(
///   title: brandName,
///   themeMode: ref.watch(appThemeModeProvider),
///   routerConfig: ref.watch(appRouterProvider),
/// );
/// ```
abstract final class AppMaterialDefaults {
  static const locale = Locale('es', 'PE');
  static const supportedLocales = [Locale('es', 'PE'), Locale('es')];
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = GlobalMaterialLocalizations.delegates;
  static const scrollBehavior = AppScrollBehavior();

  /// `MaterialApp.router` con los valores por defecto de Apamuy.
  static MaterialApp router({
    required String title,
    required RouterConfig<Object> routerConfig,
    ThemeMode themeMode = ThemeMode.system,
    TransitionBuilder? builder,
    Key? key,
  }) => MaterialApp.router(
    key: key,
    title: title,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    routerConfig: routerConfig,
    builder: builder,
    scrollBehavior: scrollBehavior,
    locale: locale,
    supportedLocales: supportedLocales,
    localizationsDelegates: localizationsDelegates,
  );
}

/// En web y escritorio Flutter solo arrastra con el dedo: sin esto, los
/// carruseles y filas horizontales no se mueven con el mouse.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {...super.dragDevices, PointerDeviceKind.mouse, PointerDeviceKind.trackpad};
}
