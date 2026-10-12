import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';

/// Primera hoja de un `.xlsx` o un `.csv` (coma o punto y coma), con cada celda
/// como texto. Lanza [FormatException] si el archivo no se puede leer.
List<List<String>> readSpreadsheet(Uint8List bytes, String fileName) {
  final name = fileName.toLowerCase();
  if (name.endsWith('.xlsx')) return _readXlsx(bytes);
  if (name.endsWith('.csv') || name.endsWith('.txt')) return _readCsv(bytes);
  throw const FormatException('Formato no soportado');
}

/// La plantilla en CSV con BOM: Excel la abre con las tildes bien.
Uint8List templateCsv(List<List<String>> rows) => Uint8List.fromList(utf8.encode(Csv(addBom: true).encode(rows)));

List<List<String>> _readCsv(Uint8List bytes) {
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('\u{FEFF}')) text = text.substring(1);
  return [
    for (final row in Csv().decode(text)) [for (final cell in row) '$cell'],
  ];
}

/// Lector mínimo de `.xlsx` (un zip con XML): textos compartidos, celdas en
/// línea, números y booleanos de la primera hoja. Sin fórmulas ni formatos.
List<List<String>> _readXlsx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw const FormatException('No es un .xlsx');
  }
  XmlDocument? xml(String path) {
    final file = archive.findFile(path);
    return file == null ? null : XmlDocument.parse(utf8.decode(file.content));
  }

  final shared = [
    for (final item in xml('xl/sharedStrings.xml')?.findAllElements('si') ?? const <XmlElement>[])
      item.findAllElements('t').map((t) => t.innerText).join(),
  ];
  final sheet = xml(_firstSheetPath(xml)) ?? (throw const FormatException('El .xlsx no tiene hojas'));

  final rows = <List<String>>[];
  for (final row in sheet.findAllElements('row')) {
    final rowNumber = int.tryParse(row.getAttribute('r') ?? '') ?? rows.length + 1;
    while (rows.length < rowNumber - 1) {
      rows.add([]);
    }
    final cells = <String>[];
    for (final cell in row.findElements('c')) {
      final column = _columnIndex(cell.getAttribute('r')) ?? cells.length;
      while (cells.length < column) {
        cells.add('');
      }
      cells.add(_cellText(cell, shared));
    }
    rows.add(cells);
  }
  return rows;
}

String _firstSheetPath(XmlDocument? Function(String) xml) {
  final sheetId = xml('xl/workbook.xml')?.findAllElements('sheet').firstOrNull?.getAttribute('r:id');
  final target = xml(
    'xl/_rels/workbook.xml.rels',
  )?.findAllElements('Relationship').where((r) => r.getAttribute('Id') == sheetId).firstOrNull?.getAttribute('Target');
  if (target == null) return 'xl/worksheets/sheet1.xml';
  return target.startsWith('/') ? target.substring(1) : 'xl/$target';
}

String _cellText(XmlElement cell, List<String> shared) {
  final value = cell.getElement('v')?.innerText ?? '';
  return switch (cell.getAttribute('t')) {
    's' => shared.elementAtOrNull(int.tryParse(value) ?? -1) ?? '',
    'inlineStr' => cell.findAllElements('t').map((t) => t.innerText).join(),
    'str' || 'b' || 'e' => value,
    _ => _number(value),
  };
}

/// Excel guarda 17.5 como "17.499999999999996" a veces: se redondea a céntimos.
String _number(String value) {
  final dot = value.indexOf('.');
  if (dot == -1 || value.length - dot - 1 <= 4) return value;
  final number = double.tryParse(value);
  if (number == null) return value;
  return number.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// "C12" → 2.
int? _columnIndex(String? reference) {
  final letters = RegExp('^[A-Z]+').stringMatch(reference ?? '');
  if (letters == null) return null;
  var index = 0;
  for (final code in letters.codeUnits) {
    index = index * 26 + (code - 64);
  }
  return index - 1;
}
