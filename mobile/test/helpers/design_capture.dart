import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadDesignFonts() async {
  for (final (family, asset) in [
    ('Jakarta', 'assets/fonts/PlusJakartaSans-Variable.ttf'),
    ('Outfit', 'assets/fonts/Outfit-Variable.ttf'),
    ('Bungee', 'assets/fonts/Bungee-Regular.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
}

/// Captura la pantalla completa con dock y overlays, usando imágenes reales locales.
Future<void> captureCity(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_CITY')) return;
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 600));
  await expectLater(find.byType(Overlay).first, matchesGoldenFile('../../../docs/ui/ciudad/$name.png'));
}
