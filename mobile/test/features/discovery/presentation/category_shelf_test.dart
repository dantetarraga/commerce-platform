import 'package:apamuy/features/discovery/domain/moment.dart';
import 'package:apamuy/features/home/presentation/widgets/sections/category_shelf.dart';
import 'package:apamuy/features/stores/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const slugs = ['restaurantes', 'bodegas', 'farmacia', 'postres', 'licores', 'mercado', 'regalos', 'encargos'];
  final all = [for (final s in slugs) Category(id: 'cat_$s', name: s, slug: s)];

  test('Cerca muestra 4 accesos principales y resalta el del momento', () {
    final night = CategoryShelf.pick(all, Moment.night);
    expect(night.main.map((c) => c.slug), ['restaurantes', 'mercado', 'farmacia', 'bodegas']);
    expect(night.highlighted, 'restaurantes');
    expect(night.rest, hasLength(4));

    final breakfast = CategoryShelf.pick(all, Moment.breakfast);
    expect(breakfast.highlighted, 'mercado');
  });

  test('si la categoría del momento no está entre las 4, entra en el último lugar', () {
    final afternoon = CategoryShelf.pick(all, Moment.afternoon);
    expect(afternoon.main.map((c) => c.slug), ['restaurantes', 'mercado', 'farmacia', 'postres']);
    expect(afternoon.highlighted, 'postres');
    expect(afternoon.rest.map((c) => c.slug), contains('bodegas'));
  });
}
