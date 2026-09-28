import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

Widget _app(Widget child, {bool reduced = false}) => MaterialApp(
  theme: AppTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('el dock ofrece navegación también al lector de pantalla', (tester) async {
    final semantics = tester.ensureSemantics();
    var selected = 0;
    await tester.pumpWidget(_app(AppNavigationDock(index: 0, onSelected: (index) => selected = index)));
    final node = tester.getSemantics(find.bySemanticsLabel('Buscar'));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    expect(selected, 1);
    semantics.dispose();
  });

  testWidgets('agregado rápido espera el resultado y evita peticiones duplicadas', (tester) async {
    final result = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 180,
          child: AppProductCard(
            data: const ProductCardData(id: 'p', name: 'Pan', price: Money(500)),
            variant: AppProductCardVariant.featured,
            onTap: () {},
            onQuickAdd: () {
              calls++;
              return result.future;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(QuickAddButton));
    await tester.pump();
    await tester.tap(find.byType(QuickAddButton));
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<QuickAddButton>(find.byType(QuickAddButton)).loading, isTrue);
    result.complete(false);
    await tester.pumpAndSettle();
    expect(tester.widget<QuickAddButton>(find.byType(QuickAddButton)).loading, isFalse);
    expect(find.byType(AppNetworkImage), findsOneWidget);
  });

  testWidgets('el agregado destacado es accesible sin abrir el producto', (tester) async {
    final semantics = tester.ensureSemantics();
    var added = 0;
    var opened = 0;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 180,
          child: AppProductCard(
            data: const ProductCardData(id: 'p', name: 'Pan', price: Money(500)),
            variant: AppProductCardVariant.featured,
            onTap: () => opened++,
            onQuickAdd: () async {
              added++;
              return true;
            },
          ),
        ),
        reduced: true,
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Agregar a la bolsa'));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(added, 1);
    expect(opened, 0);
    semantics.dispose();
  });

  testWidgets('avatar con semilla usa una ilustración local también sin foto', (tester) async {
    await tester.pumpWidget(_app(const AppAvatar(seed: 'cuenta-uno', imageUrl: '  ', initials: 'AB')));
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(picture.bytesLoader, isA<SvgAssetLoader>());
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(AppAvatar.illustrationAsset('cuenta-uno'), AppAvatar.illustrationAsset('cuenta-uno'));
    // Todos los avatares del conjunto están disponibles en el paquete.
    for (var index = 0; index < 12; index++) {
      final data = await DefaultAssetBundle.of(tester.element(find.byType(AppAvatar))).loadString('assets/avatars/notionist_$index.svg');
      expect(data, contains('<svg'));
    }
  });

  testWidgets('imagen vacía conserva su espacio y no intenta descargar', (tester) async {
    await tester.pumpWidget(_app(const AppNetworkImage(url: '  ', width: 144, height: 110)));
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.text('Sin foto'), findsOneWidget);
    expect(tester.getSize(find.byType(AppNetworkImage)), const Size(144, 110));
    await tester.pumpWidget(_app(const AppNetworkImage(url: null, width: 24, height: 24)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('la carga de imágenes y sus transiciones respetan movimiento reducido', (tester) async {
    await tester.pumpWidget(_app(const AppNetworkImage(url: 'https://example.com/photo.jpg', width: 120, height: 90), reduced: true));
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.fadeInDuration, Duration.zero);
    expect(image.fadeOutDuration, Duration.zero);
    final placeholder = image.placeholder!(tester.element(find.byType(CachedNetworkImage)), image.imageUrl);
    await tester.pumpWidget(_app(SizedBox(width: 120, height: 90, child: placeholder), reduced: true));
    // Con movimiento reducido el placeholder es un bloque quieto, sin barrido.
    expect(find.byWidgetPredicate((w) => w is sk.Skeletonizer && w.effect is sk.SolidColorEffect), findsOneWidget);
  });

  testWidgets('favorito recibe toques en los bordes de su área de 48 puntos', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(FavoriteButton(isFavorite: false, onPressed: () => taps++)));
    final rect = tester.getRect(find.byType(FavoriteButton));
    await tester.tapAt(Offset(rect.left + 2, rect.center.dy));
    expect(taps, 1);
  });

  testWidgets('agregar recibe toques en los bordes de su área de 48 puntos', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(QuickAddButton(onPressed: () => taps++), reduced: true));
    final rect = tester.getRect(find.byType(QuickAddButton));
    await tester.tapAt(Offset(rect.left + 2, rect.center.dy));
    expect(taps, 1);
  });

  testWidgets('lector de pantalla puede guardar un negocio sin abrirlo', (tester) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    var saved = 0;
    await tester.pumpWidget(
      _app(
        AppStoreCard(
          data: const StoreCardData(id: 'test', name: 'Negocio', etaMinutes: 20, deliveryFee: Money.zero(), isOpen: true),
          onTap: () => opened++,
          onFavoriteToggle: () => saved++,
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Guardar en favoritos'));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    expect(saved, 1);
    expect(opened, 0);
    semantics.dispose();
  });

  testWidgets('activar movimiento reducido termina la animación de entrada', (tester) async {
    const child = FadeSlideIn(duration: Duration(seconds: 2), child: Text('Listo'));
    await tester.pumpWidget(_app(child));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_app(child, reduced: true));
    expect(find.ancestor(of: find.text('Listo'), matching: find.byType(Opacity)), findsNothing);
    // MaterialApp también interpola el tema durante 200 ms.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
