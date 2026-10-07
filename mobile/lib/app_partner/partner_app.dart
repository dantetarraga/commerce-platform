import 'package:chaski/app_partner/router/partner_router.dart';
import 'package:chaski/core/config/theme_mode_provider.dart';
import 'package:chaski/shared/design_system/brand/brand_logo.dart';
import 'package:chaski/shared/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Apamuy Socios: la app de negocios y repartidores (flavor `partner`).
class PartnerApp extends ConsumerWidget {
  const PartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '$brandName Socios',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(appThemeModeProvider),
      routerConfig: ref.watch(partnerRouterProvider),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
