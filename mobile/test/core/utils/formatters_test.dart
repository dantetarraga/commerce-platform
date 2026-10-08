import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/core/utils/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dinero con el formato usado en Perú: S/ adelante y punto decimal', () {
    expect(Formatters.money(const Money(6500)), 'S/ 65.00');
    expect(Formatters.money(const Money(125050)), 'S/ 1,250.50');
  });

  test('monto corto sin céntimos cuando no hay', () {
    expect(Formatters.shortMoney(const Money(1200)), 'S/ 12');
    expect(Formatters.shortMoney(const Money(1250)), 'S/ 12.50');
    expect(Formatters.keepCurrencyTogether('Vendiste S/ 12'), 'Vendiste S/ 12');
  });

  test('distancia en metros bajo 1 km y con un decimal desde 1 km', () {
    expect(Formatters.distance(0.6), '600 m');
    expect(Formatters.distance(1.45), '1.5 km');
    expect(Formatters.meters(850), '850 m');
    expect(Formatters.meters(1240), '1.2 km');
  });

  test('tiempo estimado con raya y cuenta regresiva m:ss', () {
    expect(Formatters.eta(25), '20–30 min');
    expect(Formatters.minutesSeconds(65), '1:05');
    expect(Formatters.minutesSeconds(720), '12:00');
    expect(Formatters.minutesSeconds(-3), '0:00');
  });

  test('horario desde minutos en 12 h, incluso pasada la medianoche', () {
    expect(Formatters.timeOfDay(660), '11:00 am');
    expect(Formatters.timeOfDay(18 * 60 + 30), '6:30 pm');
    expect(Formatters.timeOfDay(1440 + 60), '1:00 am');
    expect(Formatters.timeOfDay(12 * 60), '12:00 pm');
  });

  test('la hora de un momento en 12 h', () {
    expect(Formatters.clock(DateTime(2026, 1, 1, 13, 12)), '1:12 pm');
    expect(Formatters.clock(DateTime(2026, 1, 1, 0, 5)), '12:05 am');
    expect(Formatters.hour12(DateTime(2026, 1, 1, 18, 30)), '6:30');
    expect(Formatters.meridiem(DateTime(2026, 1, 1, 18, 30)), 'pm');
  });

  test('día relativo y frase de cuándo', () {
    final now = DateTime(2026, 9, 22, 12);
    expect(Formatters.relativeDay(DateTime(2026, 9, 22, 7, 2), now: now), 'Hoy, 7:02 am');
    expect(Formatters.relativeDay(DateTime(2026, 9, 21, 20, 15), now: now), 'Ayer, 8:15 pm');
    expect(Formatters.relativeDay(DateTime(2026, 9, 19), now: now), 'Hace 3 días');
    expect(Formatters.relativeDay(DateTime(2026, 9, 2), now: now), '2 sep');
    expect(Formatters.whenPhrase(DateTime(2026, 9, 22, 18, 30), now: now), 'hoy a las 6:30 pm');
    expect(Formatters.whenPhrase(DateTime(2026, 9, 23, 7), now: now), 'mañana a las 7:00 am');
    expect(Formatters.whenPhrase(DateTime(2026, 9, 26, 9), now: now), 'el sábado a las 9:00 am');
    expect(Formatters.whenPhrase(DateTime(2026, 10, 2, 9), now: now), 'el 2 oct a las 9:00 am');
  });

  test('foldAccents quita tildes y mayúsculas; normalizeForSearch además recorta', () {
    expect(foldAccents('Ají de Gallina'), 'aji de gallina');
    expect(foldAccents('PINGÜINO Ñandú'), 'pinguino nandu');
    expect(normalizeForSearch('  Ají '), 'aji');
  });
}
