import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;

Widget _app({bool reduced = false, String asset = AppRiveSuccess.asset}) => MaterialApp(
  theme: AppTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: Center(child: AppRiveSuccess(assetPath: asset)),
    ),
  ),
);

Future<void> _load(WidgetTester tester) async {
  for (var i = 0; i < 50 && find.byType(rive.RiveArtboardWidget).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  expect(find.byType(rive.RiveArtboardWidget), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => expect(await rive.RiveNative.init(), isTrue));

  testWidgets('el archivo Rive de Chaski se reproduce una vez y termina', (tester) async {
    final file = await tester.runAsync(() => rive.File.asset(AppRiveSuccess.asset, riveFactory: rive.Factory.flutter));
    expect(file, isNotNull);
    final artboard = file!.artboard('ChaskiSuccess');
    expect(artboard, isNotNull);
    final animation = artboard!.animationNamed('confirm');
    expect(animation, isNotNull);
    expect(animation!.duration, closeTo(1.2, 0.01));
    expect(animation.advanceAndApply(0.2), isTrue);
    animation.advanceAndApply(2);
    expect(animation.advanceAndApply(0.1), isFalse);
    animation.dispose();
    artboard.dispose();
    file.dispose();
  });

  testWidgets('conserva el fotograma final sin seguir animando', (tester) async {
    await tester.pumpWidget(_app());
    await _load(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    final widget = tester.widget<rive.RiveArtboardWidget>(find.byType(rive.RiveArtboardWidget));
    expect((widget.painter as rive.BasicArtboardPainter).isTickerActive, isFalse);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('movimiento reducido muestra una confirmación estática', (tester) async {
    await tester.pumpWidget(_app(reduced: true));
    expect(find.byType(rive.RiveArtboardWidget), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('activar movimiento reducido detiene y libera la animación', (tester) async {
    await tester.pumpWidget(_app());
    await _load(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_app(reduced: true));
    await tester.pumpAndSettle();
    expect(find.byType(rive.RiveArtboardWidget), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un archivo ausente mantiene la alternativa estática', (tester) async {
    await tester.pumpWidget(_app(asset: 'assets/animations/no_existe.riv'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.byType(rive.RiveArtboardWidget), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('salir mientras carga no actualiza un widget desmontado', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
