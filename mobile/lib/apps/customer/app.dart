import 'package:apamuy/apps/customer/router/app_router.dart';
import 'package:apamuy/apps/routing/push_opened_listener.dart';
import 'package:apamuy/core/config/theme_mode_provider.dart';
import 'package:apamuy/features/orders/orders_customer.dart';
import 'package:apamuy/shared/design_system/brand/brand_logo.dart';
import 'package:apamuy/shared/design_system/theme/app_material_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApamuyApp extends ConsumerWidget {
  const ApamuyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return PushOpenedListener(
      // Cada aviso de un pedido abre su seguimiento; el resto, la app donde estaba.
      onOpened: (data) {
        if (data['orderId'] case final orderId?) {
          router.pushNamed(OrderTrackingPage.name, pathParameters: {'orderId': orderId}).ignore();
        }
      },
      child: AppMaterialDefaults.router(
        title: brandName,
        themeMode: ref.watch(appThemeModeProvider),
        routerConfig: router,
      ),
    );
  }
}
