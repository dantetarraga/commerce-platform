import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/domain/quantity.dart';
import 'package:apamuy/features/products/domain/entities/product.dart';
import 'package:apamuy/features/products/domain/entities/product_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pizza = Product(
    id: 'pizza',
    storeId: 'qori',
    storeName: 'Pizzería Qori',
    name: 'Pizza Andina',
    basePrice: Money(3200),
    isAvailable: true,
    variants: [
      ProductVariant(id: 'personal', name: 'Personal', price: Money(2200), isAvailable: false),
      ProductVariant(id: 'mediana', name: 'Mediana', price: Money(3200), isAvailable: true),
      ProductVariant(id: 'familiar', name: 'Familiar', price: Money(4600), isAvailable: true),
    ],
    options: [
      ProductOption(
        id: 'borde',
        name: 'Borde',
        minSelect: 1,
        maxSelect: 1,
        values: [
          OptionValue(id: 'clasico', name: 'Clásico', priceDelta: Money(0), isAvailable: true),
          OptionValue(id: 'queso', name: 'Relleno de queso', priceDelta: Money(600), isAvailable: true),
        ],
      ),
      ProductOption(
        id: 'extras',
        name: 'Extras',
        minSelect: 0,
        maxSelect: 2,
        values: [
          OptionValue(id: 'xqueso', name: 'Extra queso', priceDelta: Money(400), isAvailable: true),
          OptionValue(id: 'champi', name: 'Champiñones', priceDelta: Money(300), isAvailable: true),
          OptionValue(id: 'tocino', name: 'Tocino', priceDelta: Money(500), isAvailable: false),
          OptionValue(id: 'aceituna', name: 'Aceitunas', priceDelta: Money(200), isAvailable: true),
        ],
      ),
    ],
  );

  group('ProductSelection', () {
    test('preselecciona la primera variante disponible', () {
      final selection = ProductSelection.initial(pizza);
      expect(selection.variantId, 'mediana');
      expect(selection.unitPrice, const Money(3200));
    });

    test('no es válida hasta elegir las opciones obligatorias', () {
      final selection = ProductSelection.initial(pizza);
      expect(selection.isValid, isFalse);
      expect(selection.missingRequiredOptions.map((o) => o.id), ['borde']);

      expect(selection.toggleValue('borde', 'clasico').isValid, isTrue);
    });

    test('en elección única reemplaza el valor anterior', () {
      final selection = ProductSelection.initial(pizza).toggleValue('borde', 'clasico').toggleValue('borde', 'queso');
      expect(selection.selectedIn('borde'), {'queso'});
    });

    test('respeta maxSelect e ignora valores no disponibles', () {
      final selection = ProductSelection.initial(pizza)
          .toggleValue('extras', 'xqueso')
          .toggleValue('extras', 'champi')
          .toggleValue('extras', 'aceituna') // supera el máximo de 2
          .toggleValue('extras', 'tocino'); // no disponible
      expect(selection.selectedIn('extras'), {'xqueso', 'champi'});
      expect(selection.canSelectMore(pizza.options[1]), isFalse);
    });

    test('ignora variantes no disponibles', () {
      final selection = ProductSelection.initial(pizza).selectVariant('personal');
      expect(selection.variantId, 'mediana');
    });

    test('calcula precio unitario y total con variante, opciones y cantidad', () {
      final selection = ProductSelection.initial(pizza)
          .selectVariant('familiar')
          .toggleValue('borde', 'queso')
          .toggleValue('extras', 'xqueso')
          .withQuantity(Quantity.create(2).valueOrNull!);
      // 4600 + 600 + 400 = 5600 por unidad
      expect(selection.unitPrice, const Money(5600));
      expect(selection.total, const Money(11200));
    });

    test('un producto agotado nunca es válido', () {
      const soldOut = Product(
        id: 'x',
        storeId: 's',
        storeName: 'S',
        name: 'Agotado',
        basePrice: Money(500),
        isAvailable: false,
      );
      expect(ProductSelection.initial(soldOut).isValid, isFalse);
    });
  });
}
