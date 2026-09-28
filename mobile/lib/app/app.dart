import 'package:chaski/app/config/theme_mode_provider.dart';
import 'package:chaski/app/router/app_router.dart';
import 'package:chaski/shared/design_system/brand/brand_logo.dart';
import 'package:chaski/shared/design_system/theme/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChaskiApp extends ConsumerWidget {
  const ChaskiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: brandName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(appThemeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
      scrollBehavior: const _ChaskiScrollBehavior(),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

/// En web y escritorio Flutter solo arrastra con el dedo: sin esto, los
/// carruseles y filas horizontales no se mueven con el mouse.
class _ChaskiScrollBehavior extends MaterialScrollBehavior {
  const _ChaskiScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {...super.dragDevices, PointerDeviceKind.mouse, PointerDeviceKind.trackpad};
}
