import 'package:chaski/features/auth/presentation/widgets/splash_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la entrada parte igual que el arranque nativo y termina con la moto al centro', () {
    final start = SplashFrame.at(intro: 0, exit: 0);
    expect(start.markOpacity, 1);
    expect(start.discScale, 0);
    expect(start.riderX, lessThan(-1));
    expect(start.wordOpacity, 0);

    final end = SplashFrame.at(intro: 1, exit: 0);
    expect(end.markOpacity, 0);
    expect(end.discScale, closeTo(1, 1e-9));
    expect(end.riderX, closeTo(0, 1e-9));
    expect(end.wordOpacity, 1);
    expect(end.wordY, closeTo(0, 1e-9));
    expect(end.reveal, 0);
  });

  test('la salida lleva la moto a la derecha y el disco cubre todo', () {
    expect(SplashFrame.at(intro: 1, exit: 0.3).riderX, greaterThan(0));
    final end = SplashFrame.at(intro: 1, exit: 1);
    expect(end.riderX, greaterThan(1));
    expect(end.wordOpacity, 0);
    expect(end.reveal, 1);
    expect(SplashFrame.at(intro: 1, exit: 0.2).reveal, 0);
  });
}
