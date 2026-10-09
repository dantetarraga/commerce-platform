import 'dart:async';

import 'package:apamuy/apps/partner/router/partner_router.dart';
import 'package:apamuy/apps/routing/push_opened_listener.dart';
import 'package:apamuy/core/config/theme_mode_provider.dart';
import 'package:apamuy/core/push/local_alerts.dart';
import 'package:apamuy/features/courier_deliveries/courier_deliveries.dart';
import 'package:apamuy/features/merchant_orders/merchant_orders.dart';
import 'package:apamuy/shared/design_system/brand/brand_logo.dart';
import 'package:apamuy/shared/design_system/theme/app_material_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Apamuy Socios: la app de negocios y repartidores (flavor `partner`).
class PartnerApp extends ConsumerWidget {
  const PartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(partnerRouterProvider);
    return PushOpenedListener(
      onOpened: (data) {
        unawaited(LocalAlerts.cancelAlarm());
        switch (data['type']) {
          case 'NEW_ORDER' || 'ORDER_CANCELLED':
            router.goNamed(MerchantHomePage.name);
          case 'ORDER_READY':
            router.goNamed(CourierHomePage.name);
        }
      },
      // Con la app abierta la alarma suena desde el tablero: la del aviso ya sobra.
      onResumed: () => unawaited(LocalAlerts.cancelAlarm()),
      child: AppMaterialDefaults.router(
        title: '$brandName Socios',
        themeMode: ref.watch(appThemeModeProvider),
        routerConfig: router,
      ),
    );
  }
}
