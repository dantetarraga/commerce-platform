import 'package:apamuy/features/discovery/domain/moment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime at(int hour) => DateTime(2026, 9, 23, hour);

  test('el momento sigue la hora del día', () {
    expect(Moment.at(at(6)), Moment.breakfast);
    expect(Moment.at(at(12)), Moment.lunch);
    expect(Moment.at(at(16)), Moment.afternoon);
    expect(Moment.at(at(21)), Moment.night);
    expect(Moment.at(at(2)), Moment.night);
  });

  test('cada momento tiene etiqueta, saludo, pistas y categorías destacadas', () {
    for (final m in Moment.values) {
      expect(m.tag, isNotEmpty);
      expect(m.greeting, isNotEmpty);
      expect(m.searchHints, isNotEmpty);
      expect(m.featuredCategories, hasLength(2));
    }
    expect(Moment.lunch.collectionTitle, contains('Menú del día'));
  });
}
