import 'dart:convert';
import 'dart:typed_data';

import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/spreadsheet_reader.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un `.xlsx` mínimo como lo guarda Excel: textos compartidos, un número con
/// el error de coma flotante de siempre y una celda vacía en medio.
Uint8List _xlsx() {
  const workbook = '''
<workbook xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets><sheet name="Carta" sheetId="1" r:id="rId1"/></sheets>
</workbook>''';
  const rels = '''
<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>''';
  const shared = '''
<sst><si><t>nombre</t></si><si><t>precio</t></si><si><t>stock</t></si><si><r><t>Chicha </t></r><r><t>morada</t></r></si></sst>''';
  const sheet = '''
<worksheet><sheetData>
  <row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="C1" t="s"><v>2</v></c></row>
  <row r="3"><c r="A3" t="s"><v>3</v></c><c r="B3"><v>17.499999999999996</v></c><c r="C3"><v>20</v></c></row>
  <row r="4"><c r="A4" t="inlineStr"><is><t>Té</t></is></c><c r="C4"><v>5</v></c></row>
</sheetData></worksheet>''';
  final archive = Archive();
  for (final (path, xml) in [
    ('xl/workbook.xml', workbook),
    ('xl/_rels/workbook.xml.rels', rels),
    ('xl/sharedStrings.xml', shared),
    ('xl/worksheets/sheet1.xml', sheet),
  ]) {
    archive.addFile(ArchiveFile.bytes(path, utf8.encode(xml)));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  test('lee un .xlsx respetando filas vacías y columnas salteadas', () {
    final sheet = readSpreadsheet(_xlsx(), 'Carta.XLSX');
    expect(sheet, [
      ['nombre', 'precio', 'stock'],
      <String>[],
      ['Chicha morada', '17.5', '20'],
      ['Té', '', '5'],
    ]);
    final rows = (sheetToRows(sheet) as SheetRows).rows;
    expect(rows.map((r) => r.line), [3, 4]);
  });

  test('lee un .csv con punto y coma y BOM, como lo guarda Excel en español', () {
    final bytes = Uint8List.fromList(utf8.encode('\u{FEFF}nombre;precio\r\n"Pollo; entero";62,00\r\n'));
    expect(readSpreadsheet(bytes, 'carta.csv'), [
      ['nombre', 'precio'],
      ['Pollo; entero', '62,00'],
    ]);
  });

  test('la plantilla se vuelve a leer igual', () {
    expect(readSpreadsheet(templateCsv(templateSheet), 'plantilla.csv'), templateSheet);
  });

  test('otro formato o un archivo dañado no se lee', () {
    expect(() => readSpreadsheet(Uint8List(4), 'carta.xls'), throwsFormatException);
    expect(() => readSpreadsheet(Uint8List.fromList([1, 2, 3]), 'carta.xlsx'), throwsFormatException);
  });
}
