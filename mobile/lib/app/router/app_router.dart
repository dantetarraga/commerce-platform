import 'package:chaski/app/purchase_bar/with_purchase_bar.dart';
import 'package:chaski/app/router/routes.dart';
import 'package:chaski/app/router/scaffold_with_nav.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/checkout/checkout.dart';
import 'package:chaski/features/discovery/discovery.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/home/home.dart';
import 'package:chaski/features/notifications/notifications.dart';
import 'package:chaski/features/onboarding/onboarding.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/features/products/products.dart';
import 'package:chaski/features/profile/profile.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // El router se crea una sola vez; los cambios de sesión solo disparan un
  // nuevo `redirect` a través de este listenable.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authSessionProvider, (_, _) => refresh.value++)
    ..listen(onboardingStatusProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: SplashPage.name,
        pageBuilder: (_, state) => _fadeThroughPage(state, const SplashPage()),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: OnboardingPage.name,
        pageBuilder: (_, state) => _fadeThroughPage(state, const OnboardingPage()),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: PhoneEntryPage.name,
        pageBuilder: (_, state) => _fadeThroughPage(state, const PhoneEntryPage()),
        routes: [
          GoRoute(
            path: RoutePaths.otp,
            name: OtpPage.name,
            builder: (_, _) => const OtpPage(),
            routes: [
              GoRoute(
                path: RoutePaths.profileSetup,
                name: ProfileSetupPage.name,
                builder: (_, _) => const ProfileSetupPage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (_, state, shell) => _fadeThroughPage(state, ScaffoldWithNav(shell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: HomePage.name,
                builder: (_, _) => const HomePage(),
                routes: [
                  GoRoute(
                    path: RoutePaths.categoryStores,
                    name: CategoryStoresPage.name,
                    builder: (_, state) => CategoryStoresPage(categoryId: state.pathParameters['categoryId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RoutePaths.explore, name: ExplorePage.name, builder: (_, _) => const ExplorePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: ProfilePage.name,
                builder: (_, _) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: RoutePaths.orders,
                    name: OrdersPage.name,
                    builder: (context, _) => OrdersPage(
                      onExplore: () => context.goNamed(HomePage.name),
                      onOpenStore: (storeId) => context.pushNamed(StoreDetailPage.name, pathParameters: {'storeId': storeId}),
                    ),
                  ),
                  GoRoute(path: RoutePaths.favorites, name: FavoritesPage.name, builder: (_, _) => const FavoritesPage()),
                ],
              ),
            ],
          ),
        ],
      ),
      // Pantallas de detalle: a pantalla completa, sobre la barra de navegación.
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.storeDetail,
        name: StoreDetailPage.name,
        builder: (_, state) => WithPurchaseBar(
          child: StoreDetailPage(
            storeId: state.pathParameters['storeId']!,
            args: state.extra is StoreRouteArgs ? state.extra! as StoreRouteArgs : const StoreRouteArgs(),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.productDetail,
        name: ProductDetailPage.name,
        builder: (_, state) => ProductDetailPage(productId: state.pathParameters['productId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.checkout,
        name: CheckoutPage.name,
        builder: (_, _) => const CheckoutPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.orderTracking,
        name: OrderTrackingPage.name,
        builder: (_, state) => OrderTrackingPage(orderId: state.pathParameters['orderId']!),
        routes: [
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: RoutePaths.orderHelp,
            name: OrderHelpPage.name,
            builder: (_, state) => OrderHelpPage(orderId: state.pathParameters['orderId']!),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.notifications,
        name: NotificationsPage.name,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.addressForm,
        name: AddressFormPage.name,
        builder: (_, _) => const AddressFormPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

String? _redirect(Ref ref, String location) {
  final session = ref.read(authSessionProvider);
  final onboarding = ref.read(onboardingStatusProvider);

  // Todavía restaurando la sesión o leyendo preferencias.
  if (!session.hasValue || !onboarding.hasValue) {
    return location == RoutePaths.splash ? null : RoutePaths.splash;
  }

  final isLoggedIn = session.value != null;

  if (!isLoggedIn) {
    if (onboarding.value != true) {
      return location == RoutePaths.onboarding ? null : RoutePaths.onboarding;
    }
    final inLogin = location == RoutePaths.login || location.startsWith('${RoutePaths.login}/');
    return inLogin ? null : RoutePaths.login;
  }

  return RoutePaths.isPublic(location) ? RoutePaths.home : null;
}

/// Cambios de "contexto" (splash → onboarding → entrada → app): la pantalla
/// nueva entra con fade y una escala leve, en vez del corte seco de `go`.
CustomTransitionPage<void> _fadeThroughPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(curved), child: child),
      );
    },
  );
}
