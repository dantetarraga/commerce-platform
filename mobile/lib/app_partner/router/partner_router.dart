import 'package:chaski/app_partner/router/partner_routes.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/courier_deliveries/courier_deliveries.dart';
import 'package:chaski/features/merchant_orders/merchant_orders.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/brand/brand_logo.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_router.g.dart';

final partnerNavigatorKey = GlobalKey<NavigatorState>();

/// Router de Chaski Socios. Entra quien tiene rol de negocio o repartidor;
/// el resto ve [NotPartnerPage].
@Riverpod(keepAlive: true)
GoRouter partnerRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authSessionProvider, (_, _) => refresh.value++)
    ..listen(partnerModePreferenceProvider, (_, _) => refresh.value++)
    ..listen(splashGateProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: partnerNavigatorKey,
    initialLocation: PartnerRoutePaths.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: PartnerRoutePaths.splash,
        name: SplashPage.name,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: PartnerRoutePaths.login,
        name: PhoneEntryPage.name,
        builder: (_, _) => const PhoneEntryPage(
          title: 'Entra a $brandName Socios',
          subtitle: 'Usa el celular con el que te afiliamos. Te mandamos un código por SMS.',
          demoAccounts: [
            (label: 'Negocio', phone: FakeAuthRemoteDataSource.demoMerchantPhone),
            (label: 'Repartidor', phone: FakeAuthRemoteDataSource.demoCourierPhone),
          ],
        ),
        routes: [
          GoRoute(
            path: PartnerRoutePaths.otp,
            name: OtpPage.name,
            // Un número sin cuenta no es socio: aquí no se crean cuentas.
            builder: (_, _) => OtpPage(onProfileRequired: (context) => context.goNamed(NotPartnerPage.name)),
          ),
        ],
      ),
      GoRoute(
        path: PartnerRoutePaths.notPartner,
        name: NotPartnerPage.name,
        builder: (context, _) => NotPartnerPage(onUseAnotherNumber: () => context.goNamed(PhoneEntryPage.name)),
      ),
      GoRoute(
        path: PartnerRoutePaths.merchantHome,
        name: MerchantHomePage.name,
        builder: (_, _) => const MerchantHomePage(),
        routes: [
          GoRoute(
            path: PartnerRoutePaths.merchantProducts,
            name: MerchantProductsPage.name,
            builder: (_, state) => MerchantProductsPage(storeId: state.pathParameters['storeId']!),
          ),
        ],
      ),
      GoRoute(
        path: PartnerRoutePaths.courierHome,
        name: CourierHomePage.name,
        builder: (_, _) => const CourierHomePage(),
        routes: [
          GoRoute(
            path: PartnerRoutePaths.activeDelivery,
            name: ActiveDeliveryPage.name,
            builder: (_, state) => ActiveDeliveryPage(orderId: state.pathParameters['orderId']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

String? _redirect(Ref ref, String location) {
  final session = ref.read(authSessionProvider);
  if (!session.hasValue || !ref.read(splashGateProvider)) {
    return location == PartnerRoutePaths.splash ? null : PartnerRoutePaths.splash;
  }

  if (session.value == null) {
    final allowed =
        PartnerRoutePaths.isUnder(location, PartnerRoutePaths.login) || location == PartnerRoutePaths.notPartner;
    return allowed ? null : PartnerRoutePaths.login;
  }

  // Se calcula aquí y no con `activePartnerModeProvider`: el redirect corre
  // dentro del aviso de cambio de sesión, antes de que un provider derivado se
  // recalcule.
  final user = session.value!;
  final mode = resolvePartnerMode(
    availablePartnerModes(isMerchant: user.isMerchant, isCourier: user.isCourier),
    ref.read(partnerModePreferenceProvider),
  );
  if (mode == null) {
    return location == PartnerRoutePaths.notPartner ? null : PartnerRoutePaths.notPartner;
  }

  final home = switch (mode) {
    PartnerMode.merchant => PartnerRoutePaths.merchantHome,
    PartnerMode.courier => PartnerRoutePaths.courierHome,
  };
  final other = mode == PartnerMode.merchant ? PartnerRoutePaths.courierHome : PartnerRoutePaths.merchantHome;
  if (PartnerRoutePaths.isPublic(location) || PartnerRoutePaths.isUnder(location, other)) return home;
  return null;
}
