// Genera los PNG de marca (íconos y arranque nativo) con la misma "A" que dibuja la app.
// Regenerar: flutter test tool/brand/brand_assets_test.dart --update-goldens
// y después flutter_launcher_icons y flutter_native_splash (ver mobile/CLAUDE.md).
import 'package:apamuy/shared/design_system/brand/brand_logo.dart';
import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/design_capture.dart';

/// En el ícono adaptativo solo se ve el círculo central (66 de 108 dp).
const _adaptiveGlyph = 800.0;

/// 112 dp en xxxhdpi: igual que la "A" del primer cuadro de SplashPage.
const _splashGlyph = 448.0;

Future<void> _render(WidgetTester tester, String name, double size, Widget child, {Color? background}) async {
  tester.view
    ..physicalSize = Size.square(size)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        child: ColoredBox(color: background ?? Colors.transparent, child: Center(child: child)),
      ),
    ),
  );
  await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('../../assets/brand/$name.png'));
}

void main() {
  setUpAll(loadDesignFonts);

  testWidgets('cliente', (tester) async {
    await _render(tester, 'icon_customer', 1024, const BrandGlyph(size: 1024), background: AppColors.terracota);
    await _render(tester, 'icon_customer_foreground', 1024, const BrandGlyph(size: _adaptiveGlyph));
  });

  testWidgets('socios', (tester) async {
    // Solo la sombra ocre, para distinguirlo del ícono del cliente.
    await _render(tester, 'icon_partner', 1024, const BrandGlyph(size: 1024, layered: false), background: AppColors.tinta);
    await _render(tester, 'icon_partner_foreground', 1024, const BrandGlyph(size: _adaptiveGlyph, layered: false));
  });

  testWidgets('monocromo', (tester) async {
    await _render(tester, 'icon_monochrome', 1024, const BrandGlyph(size: _adaptiveGlyph, shadows: false));
  });

  testWidgets('arranque', (tester) async {
    await _render(tester, 'splash_mark', _splashGlyph, const BrandGlyph(size: _splashGlyph));
    // Android 12 recorta un círculo de 192 dp dentro de 288: la "A" queda en el centro.
    await _render(tester, 'splash_mark_android12', 1152, const BrandGlyph(size: _splashGlyph));
  });
}
