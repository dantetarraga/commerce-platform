import 'package:apamuy/app_partner/router/partner_router.dart';
import 'package:apamuy/core/config/theme_mode_provider.dart';
import 'package:apamuy/shared/design_system/brand/brand_logo.dart';
import 'package:apamuy/shared/design_system/theme/app_material_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Apamuy Socios: la app de negocios y repartidores (flavor `partner`).
class PartnerApp extends ConsumerWidget {
  const PartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppMaterialDefaults.router(
    title: '$brandName Socios',
    themeMode: ref.watch(appThemeModeProvider),
    routerConfig: ref.watch(partnerRouterProvider),
  );
}
