import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Ruta de una pantalla normal: `MaterialPage` explícita para que use la
/// transición del tema (go_router, por su cuenta, puede armarla sin transición).
GoRoute materialRoute({
  required String path,
  required String name,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  GlobalKey<NavigatorState>? parentNavigatorKey,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  name: name,
  parentNavigatorKey: parentNavigatorKey,
  routes: routes,
  pageBuilder: (context, state) => MaterialPage<void>(key: state.pageKey, name: state.name, child: builder(context, state)),
);

/// `refreshListenable` para un router que se crea una sola vez: avisa cada vez
/// que cambia alguno de [providers] (sesión, onboarding…), así go_router
/// vuelve a correr su `redirect`. Se libera junto con el provider del router.
Listenable routerRefresh(Ref ref, List<ProviderListenable<Object?>> providers) {
  final refresh = ValueNotifier<int>(0);
  for (final provider in providers) {
    ref.listen(provider, (_, _) => refresh.value++);
  }
  ref.onDispose(refresh.dispose);
  return refresh;
}
