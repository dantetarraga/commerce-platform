import 'package:chaski/features/stores/domain/entities/weekly_schedule.dart';
import 'package:chaski/features/stores/presentation/widgets/store_mappers.dart';
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
    expect(nextOpeningLabelFor(schedule, tuesday.add(const Duration(hours: 10))), 'Abre hoy a las 18:00');
  });

  test('abre mañana si hoy ya cerró', () {
    expect(nextOpeningLabelFor(schedule, tuesday.add(const Duration(hours: 23))), 'Abre mañana a las 07:00');
  });

  test('nombra el día si falta más', () {
    expect(nextOpeningLabelFor(schedule, DateTime(2026, 9, 24, 13)), 'Abre el sábado a las 09:00');
  });

  test('sin horarios no hay próxima apertura', () {
    expect(nextOpeningLabelFor(const WeeklySchedule([]), tuesday), isNull);
  });

  test('la próxima apertura como fecha para programar', () {
    expect(nextOpeningAt(schedule, tuesday.add(const Duration(hours: 23))), DateTime(2026, 9, 23, 7));
    expect(nextOpeningAt(const WeeklySchedule([]), tuesday), isNull);
  });

  test('dice a qué hora cierra si está abierto', () {
    expect(closingLabelFor(schedule, tuesday.add(const Duration(hours: 19))), 'Cierra 22:00');
    expect(closingLabelFor(schedule, tuesday.add(const Duration(hours: 10))), isNull);
  });

  test('un turno que cruza la medianoche sigue abierto de madrugada', () {
    const night = WeeklySchedule([OpeningHours(dayOfWeek: 2, opensAt: 20 * 60, closesAt: 2 * 60)]);
    expect(closingLabelFor(night, DateTime(2026, 9, 23, 1)), 'Cierra 02:00');
  });
}
