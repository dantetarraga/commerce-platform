import 'package:chaski/features/auth/presentation/widgets/splash_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la entrada parte con el pedido lejos e invisible y termina asentado', () {
    final start = SplashFrame.at(intro: 0, loop: null, exit: 0);
    expect(start.dotOpacity, 0);
    expect(start.dotOffset, const Offset(-150, -60));
    expect(start.letterOpacity(0), 0);

    final end = SplashFrame.at(intro: 1, loop: null, exit: 0);
    expect(end.dotOffset, Offset.zero);
    expect(end.dotScale, 1);
    expect(end.bodyAngle, 0);
    for (var i = 0; i < 6; i++) {
      expect(end.letterOpacity(i), 1);
    }
    expect(end.letterY(0), closeTo(0, 1e-9));
  });

  test('en el relevo el pedido sale por la derecha y desaparece un instante', () {
    expect(SplashFrame.at(intro: 1, loop: 0.3, exit: 0).dotOpacity, 0);
    expect(SplashFrame.at(intro: 1, loop: 0.15, exit: 0).dotOffset.dx, greaterThan(0));
    expect(SplashFrame.at(intro: 1, loop: 0.45, exit: 0).dotOffset.dx, lessThan(0));
    // La ola levanta la primera letra justo cuando llega el pedido.
    expect(SplashFrame.at(intro: 1, loop: 0.5, exit: 0).letterY(0), closeTo(0, 1e-9));
    expect(SplashFrame.at(intro: 1, loop: 0.62, exit: 0).letterY(0), -6);
  });

  test('la salida desvanece la marca y la cortina cubre todo', () {
    final end = SplashFrame.at(intro: 1, loop: null, exit: 1);
    expect(end.contentOpacity, 0);
    expect(end.contentScale, closeTo(1.15, 1e-9));
    expect(end.reveal, 1);
    expect(SplashFrame.at(intro: 1, loop: null, exit: 0.1).reveal, 0);
  });
}
