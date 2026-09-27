import 'package:chaski/features/cart/cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/design_capture.dart';

void main() {
  setUpAll(loadDesignFonts);

  testWidgets('"Repetir" vuelve a poner el último pedido en la bolsa', (tester) async {
    final container = await pumpChaski(tester, signedIn: true, disableAnimations: true);
    final repeat = find.bySemanticsLabel(RegExp('^Repetir pedido de Picantería Doña Rosa'));
    for (var i = 0; i < 30 && repeat.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -160));
      await settle(tester, frames: 5);
    }
    await tester.tap(repeat.hitTestable().first);
    await settle(tester, frames: 30);

    final cart = container.read(cartControllerProvider).value!;
    expect(cart.store?.id, 'st_dona_rosa');
    expect(cart.lines.map((l) => l.productId), containsAll(['pr_caldo_cordero', 'pr_mate_coca']));
    expect(cart.lines.firstWhere((l) => l.productId == 'pr_caldo_cordero').quantity.value, 2);
    expect(tester.takeException(), isNull);
    await unmountChaski(tester, container);
    await tester.pump(const Duration(seconds: 12));
  });
}
