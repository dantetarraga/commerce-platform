import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dinero con el formato usado en Perú: S/ adelante y punto decimal', () {
    expect(Formatters.money(const Money(6500)), 'S/ 65.00');
    expect(Formatters.money(const Money(125050)), 'S/ 1,250.50');
  });

  test('distancia en metros bajo 1 km y con un decimal desde 1 km', () {
    expect(Formatters.distance(0.6), '600 m');
    expect(Formatters.distance(1.45), '1.5 km');
  });

  test('horario desde minutos, incluso pasada la medianoche', () {
    expect(Formatters.timeOfDay(660), '11:00');
    expect(Formatters.timeOfDay(1440 + 60), '01:00');
  });
}
