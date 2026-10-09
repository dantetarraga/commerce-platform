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

/// `refreshListenable` que avisa cuando cambia alguno de [providers], para que
/// go_router vuelva a correr su `redirect`.
Listenable routerRefresh(Ref ref, List<ProviderListenable<Object?>> providers) {
  final refresh = ValueNotifier<int>(0);
  for (final provider in providers) {
    ref.listen(provider, (_, _) => refresh.value++);
  }
  ref.onDispose(refresh.dispose);
  return refresh;
}
