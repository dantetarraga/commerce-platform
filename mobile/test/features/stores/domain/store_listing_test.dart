import 'package:chaski/core/domain/money.dart';
import 'package:chaski/features/stores/domain/entities/store_filter.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:flutter_test/flutter_test.dart';

StoreSummary _store(String id, {bool open = true, int fee = 300, double rating = 4.0, int reviews = 10, String? promo, DateTime? opens}) => StoreSummary(
  id: id,
  name: id,
  categoryIds: const [],
  rating: StoreRating(average: rating, count: reviews),
  distanceKm: 1,
  etaMinutes: 25,
  deliveryFee: Money(fee),
  minOrderAmount: const Money.zero(),
  isOpenNow: open,
  deliversToYou: true,
  promoLabel: promo,
  nextOpeningAt: opens,
);

void main() {
  test('los filtros aceptan según sus reglas', () {
    expect(StoreFilter.freeDelivery.accepts(_store('a', fee: 0)), isTrue);
    expect(StoreFilter.topRated.accepts(_store('a', rating: 4.6)), isTrue);
    expect(StoreFilter.topRated.accepts(_store('a', rating: 4.9, reviews: 0)), isFalse);
    expect(StoreFilter.offers.accepts(_store('a', promo: '10 % menos')), isTrue);
    expect(StoreFilter.quick, [StoreFilter.openNow, StoreFilter.freeDelivery, StoreFilter.topRated]);
  });

  test('matching aplica todos los filtros y openFirst conserva el orden', () {
    final stores = [_store('a', open: false), _store('b', fee: 0), _store('c'), _store('d', open: false, fee: 0)];
    expect(stores.matching({StoreFilter.freeDelivery}).map((s) => s.id), ['b', 'd']);
    expect(stores.matching({}).length, 4);
    expect(stores.openFirst().map((s) => s.id), ['b', 'c', 'a', 'd']);
  });

  test('orden con etiqueta para la hoja y para la frase', () {
    expect(StoreSort.rating.label, 'Mejor calificados');
    expect(StoreSort.distance.inlineLabel, 'cercanía');
  });

  test('un cerrado dice cuándo abre con la fecha del resumen', () {
    final now = DateTime(2026, 9, 22, 22);
    expect(_store('a', open: false, opens: DateTime(2026, 9, 23, 7)).closedLabel(now), 'Cerrado · abre mañana a las 7:00 am');
    expect(_store('a', open: false).closedLabel(now), 'Cerrado');
    expect(_store('a', opens: DateTime(2026, 9, 23, 7)).opensPhrase(now), isNull);
  });

  test('la búsqueda en la carta ignora tildes y mayúsculas', () {
    const aji = MenuItem(id: '1', name: 'Ají de gallina', price: Money(1500), isAvailable: true, hasChoices: false);
    const chairo = MenuItem(id: '2', name: 'Chairo', description: 'Sopa con chuño', price: Money(1200), isAvailable: true, hasChoices: false);
    const menu = StoreMenu([
      MenuSection(id: 's1', name: 'Platos', items: [aji, chairo]),
      MenuSection(id: 's2', name: 'Destacados', items: [aji]),
    ]);
    expect(menu.search('AJI'), [aji]);
    expect(menu.search('chuno'), [chairo]);
    expect(menu.search('  '), [aji, chairo]);
  });
}
