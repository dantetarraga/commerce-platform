import 'package:chaski/app/router/app_router.dart';
import 'package:chaski/core/config/theme_mode_provider.dart';
import 'package:chaski/shared/design_system/brand/brand_logo.dart';
import 'package:chaski/shared/design_system/theme/app_material_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChaskiApp extends ConsumerWidget {
  const ChaskiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppMaterialDefaults.router(
    title: brandName,
    themeMode: ref.watch(appThemeModeProvider),
    routerConfig: ref.watch(appRouterProvider),
  );
}
