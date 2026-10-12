import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lee la plantilla tal cual, con el número de fila del archivo', () {
    final result = sheetToRows(templateSheet) as SheetRows;
    expect(result.ignoredColumns, isEmpty);
    expect(result.rows, hasLength(4));
    expect(
      result.rows.first,
      const ImportRow(
        line: 2,
        cells: {
          'section': 'Pollos',
          'name': 'Pollo a la brasa entero',
          'description': 'Con papas fritas y ensalada',
          'price': '62.00',
          'available': 'sí',
        },
      ),
    );
    expect(result.rows.last.cells, containsPair('stock', 'sin límite'));
  });

  test('acepta encabezados con tildes, mayúsculas u otros nombres y salta filas vacías', () {
    final result = sheetToRows([
      ['', ''],
      ['Producto', 'Precio (S/)', 'Categoría', 'Proveedor'],
      ['Té', '2', 'Bebidas', 'Don Pepe'],
      ['', '', '', ''],
      ['Café', '4'],
    ]);
    expect(
      result,
      const SheetRows(
        [
          ImportRow(line: 3, cells: {'name': 'Té', 'price': '2', 'section': 'Bebidas'}),
          ImportRow(line: 5, cells: {'name': 'Café', 'price': '4'}),
        ],
        ignoredColumns: ['Proveedor'],
      ),
    );
  });

  test('explica qué falta', () {
    expect(sheetToRows([]), const SheetProblem('El archivo está vacío.'));
    expect(
      sheetToRows([
        ['precio'],
        ['5'],
      ]),
      isA<SheetProblem>(),
    );
    expect(
      sheetToRows([
        ['nombre', 'precio'],
      ]),
      const SheetProblem('El archivo no tiene productos.'),
    );
    final tooMany = [
      ['nombre'],
      for (var i = 0; i <= maxImportRows; i++) ['P$i'],
    ];
    expect(sheetToRows(tooMany), isA<SheetProblem>());
  });

  test('la fila sale como el JSON de products/import', () {
    expect(const ImportRow(line: 4, cells: {'name': 'Té', 'price': '2'}).toJson(), {
      'line': 4,
      'name': 'Té',
      'price': '2',
    });
  });
}
