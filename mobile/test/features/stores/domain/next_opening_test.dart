import 'package:chaski/features/stores/domain/entities/weekly_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Martes 22 de septiembre de 2026 (weekday 2 → dayOfWeek 2 en el backend).
  final tuesday = DateTime(2026, 9, 22);
  const schedule = WeeklySchedule([
    OpeningHours(dayOfWeek: 2, opensAt: 18 * 60, closesAt: 22 * 60),
    OpeningHours(dayOfWeek: 3, opensAt: 7 * 60, closesAt: 12 * 60),
    OpeningHours(dayOfWeek: 6, opensAt: 9 * 60, closesAt: 13 * 60),
  ]);

  test('abre más tarde hoy', () {
    expect(schedule.nextOpeningLabel(tuesday.add(const Duration(hours: 10))), 'Abre hoy a las 6:00 pm');
  });

  test('abre mañana si hoy ya cerró', () {
    expect(schedule.nextOpeningLabel(tuesday.add(const Duration(hours: 23))), 'Abre mañana a las 7:00 am');
  });

  test('nombra el día si falta más', () {
    expect(schedule.nextOpeningLabel(DateTime(2026, 9, 24, 13)), 'Abre el sábado a las 9:00 am');
    expect(schedule.opensPhrase(DateTime(2026, 9, 24, 13)), 'el sábado a las 9:00 am');
  });

  test('sin horarios no hay próxima apertura', () {
    expect(const WeeklySchedule([]).nextOpeningLabel(tuesday), isNull);
  });

  test('la próxima apertura como fecha para programar', () {
    expect(schedule.nextOpeningAt(tuesday.add(const Duration(hours: 23))), DateTime(2026, 9, 23, 7));
    expect(const WeeklySchedule([]).nextOpeningAt(tuesday), isNull);
  });

  test('dice a qué hora cierra si está abierto', () {
    expect(schedule.closingLabel(tuesday.add(const Duration(hours: 19))), 'Cierra 10:00 pm');
    expect(schedule.closingLabel(tuesday.add(const Duration(hours: 10))), isNull);
    expect(schedule.isOpenAt(tuesday.add(const Duration(hours: 19))), isTrue);
  });

  test('un turno que cruza la medianoche sigue abierto de madrugada', () {
    const night = WeeklySchedule([OpeningHours(dayOfWeek: 2, opensAt: 20 * 60, closesAt: 2 * 60)]);
    expect(night.closingLabel(DateTime(2026, 9, 23, 1)), 'Cierra 2:00 am');
  });
}
