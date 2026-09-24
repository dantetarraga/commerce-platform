import 'package:chaski/app/router/app_router.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';

void main() {
  testWidgets('el negocio muestra sus bloques y se guarda en favoritos', (tester) async {
    final original = FlutterError.onError;
    // La fuente de prueba (cuadrados) desborda textos: se ignoran solo esos.
    FlutterError.onError = (d) => d.toString().contains('overflowed') ? null : original?.call(d);
    addTearDown(() => FlutterError.onError = original);

    final container = await pumpChaski(tester, signedIn: true);
    final router = container.read(appRouterProvider);

    router.pushNamed(StoreDetailPage.name, pathParameters: {'storeId': 'st_dona_rosa'}).ignore();
    await settle(tester, frames: 30);

    expect(find.text('Picantería Doña Rosa'), findsWidgets);
    expect(find.text('minutos'), findsOneWidget);
    expect(find.textContaining('envío'), findsWidgets);

    await tester.tap(find.byType(FavoriteButton).first);
    await settle(tester);
    expect(container.read(isFavoriteStoreProvider('st_dona_rosa')), isTrue);

    router.goNamed(FavoritesPage.name);
    await settle(tester, frames: 30);
    expect(find.text('Mis favoritos'), findsOneWidget);
    expect(find.text('Picantería Doña Rosa'), findsWidgets);

    await tester.tap(find.text('Productos'));
    await settle(tester);
    expect(find.text('Aún no guardas productos'), findsOneWidget);

    await unmountChaski(tester, container);
  });
}
