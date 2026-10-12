import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/text_utils.dart';
import 'package:equatable/equatable.dart';

/// Carga masiva de la carta desde un Excel o CSV: el mismo formato y las mismas
/// reglas que el Portal Socios web. La app lee las celdas como texto y el
/// backend las interpreta y explica cada error (`products/import`).

const maxImportRows = 500;

/// Celdas de una fila, tal como vienen del archivo.
final class ImportRow extends Equatable {
  const ImportRow({required this.line, this.cells = const {}});

  /// Fila del archivo, para que el error se encuentre en Excel.
  final int line;

  /// `section`, `name`, `description`, `price`, `stock`, `available`, `imageUrl`.
  final Map<String, String> cells;

  Map<String, Object> toJson() => {'line': line, ...cells};

  @override
  List<Object?> get props => [line, cells];
}

final class ImportColumn {
  const ImportColumn({
    required this.field,
    required this.header,
    required this.aliases,
    required this.help,
    this.required = false,
  });

  final String field;

  /// Encabezado de la plantilla.
  final String header;

  /// Otros encabezados que también se aceptan (sin tildes ni mayúsculas).
  final List<String> aliases;
  final String help;
  final bool required;
}

const importColumns = [
  ImportColumn(
    field: 'section',
    header: 'seccion',
    aliases: ['seccion', 'categoria', 'section'],
    help: 'Dónde aparece en la carta. Si no existe, se crea.',
  ),
  ImportColumn(
    field: 'name',
    header: 'nombre',
    aliases: ['nombre', 'producto', 'name'],
    help: 'Si ya está en la carta, se actualiza ese producto.',
    required: true,
  ),
  ImportColumn(
    field: 'description',
    header: 'descripcion',
    aliases: ['descripcion', 'detalle'],
    help: 'Lo que lleva o acompaña.',
  ),
  ImportColumn(
    field: 'price',
    header: 'precio',
    aliases: ['precio', 'precio s', 'price'],
    help: 'En soles: 12.50, 12,50 o S/ 12. Obligatorio para productos nuevos.',
    required: true,
  ),
  ImportColumn(
    field: 'stock',
    header: 'stock',
    aliases: ['stock', 'cantidad'],
    help: 'Unidades disponibles. Vacío o «sin límite»: no se controla.',
  ),
  ImportColumn(
    field: 'available',
    header: 'disponible',
    aliases: ['disponible', 'activo', 'available'],
    help: '«sí» o «no». Vacío: sí.',
  ),
  ImportColumn(
    field: 'imageUrl',
    header: 'foto_url',
    aliases: ['foto url', 'foto', 'imagen', 'image url'],
    help: 'Enlace https a la foto. También puedes ponerla después desde el producto.',
  ),
];

/// Las mismas filas que la plantilla del Portal Socios web.
final templateSheet = <List<String>>[
  [for (final c in importColumns) c.header],
  ['Pollos', 'Pollo a la brasa entero', 'Con papas fritas y ensalada', '62.00', '', 'sí', ''],
  ['Pollos', '1/4 de pollo', 'Con papas y cremas', '17,50', '', 'sí', ''],
  ['Bebidas', 'Chicha morada 1 L', 'Hecha en casa', 'S/ 8', '20', 'sí', ''],
  ['Postres', 'Mazamorra morada', '', '4', 'sin límite', 'no', ''],
];

sealed class SheetParse extends Equatable {
  const SheetParse();
}

final class SheetRows extends SheetParse {
  const SheetRows(this.rows, {this.ignoredColumns = const []});

  final List<ImportRow> rows;
  final List<String> ignoredColumns;

  @override
  List<Object?> get props => [rows, ignoredColumns];
}

/// El archivo no se puede importar (vacío, sin la columna nombre, muy largo).
final class SheetProblem extends SheetParse {
  const SheetProblem(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

String _headerKey(String cell) => foldAccents(cell).replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();

bool _blank(List<String> row) => row.every((c) => c.trim().isEmpty);

/// La primera fila con datos es el encabezado. Las filas vacías se saltan, pero
/// cada fila conserva su número del archivo.
SheetParse sheetToRows(List<List<String>> sheet) {
  final headerIndex = sheet.indexWhere((row) => !_blank(row));
  if (headerIndex == -1) return const SheetProblem('El archivo está vacío.');

  final header = sheet[headerIndex];
  final fields = [
    for (final cell in header) importColumns.where((c) => c.aliases.contains(_headerKey(cell))).firstOrNull?.field,
  ];
  if (!fields.contains('name')) {
    return const SheetProblem('Falta la columna «nombre». Mira el ejemplo para ver el formato.');
  }
  final ignored = [
    for (final (i, cell) in header.indexed)
      if (cell.trim().isNotEmpty && fields[i] == null) cell.trim(),
  ];

  final rows = <ImportRow>[];
  for (final (offset, cells) in sheet.skip(headerIndex + 1).indexed) {
    if (_blank(cells)) continue;
    rows.add(
      ImportRow(
        line: headerIndex + offset + 2,
        cells: {
          for (final (i, field) in fields.indexed)
            if (field != null && i < cells.length && cells[i].trim().isNotEmpty) field: cells[i].trim(),
        },
      ),
    );
  }
  if (rows.isEmpty) return const SheetProblem('El archivo no tiene productos.');
  if (rows.length > maxImportRows) {
    return SheetProblem('El archivo tiene ${rows.length} productos. Importa hasta $maxImportRows por vez.');
  }
  return SheetRows(rows, ignoredColumns: ignored);
}

enum ImportAction { create, update, unchanged, error }

/// Qué cambia en un producto que ya está en la carta.
enum ImportChange {
  name('nombre'),
  description('descripción'),
  imageUrl('foto'),
  price('precio'),
  stock('stock'),
  available('disponible'),
  section('sección');

  const ImportChange(this.label);

  final String label;
}

final class ImportRowResult extends Equatable {
  const ImportRowResult({
    required this.line,
    required this.name,
    required this.action,
    this.errors = const [],
    this.warnings = const [],
    this.changes = const [],
    this.priceFrom,
    this.priceTo,
  });

  final int line;
  final String name;
  final ImportAction action;
  final List<String> errors;
  final List<String> warnings;
  final List<ImportChange> changes;

  /// Precio de antes (nulo en un producto nuevo) y el que queda.
  final Money? priceFrom;
  final Money? priceTo;

  @override
  List<Object?> get props => [line, name, action, errors, warnings, changes, priceFrom, priceTo];
}

/// Lo que hizo (o haría, con `dryRun`) la importación.
final class ImportResult extends Equatable {
  const ImportResult({
    required this.dryRun,
    required this.created,
    required this.updated,
    required this.unchanged,
    required this.failed,
    this.sectionsCreated = const [],
    this.rows = const [],
  });

  final bool dryRun;
  final int created;
  final int updated;
  final int unchanged;
  final int failed;
  final List<String> sectionsCreated;
  final List<ImportRowResult> rows;

  /// Productos que cambian al guardar.
  int get pending => created + updated;

  List<ImportRowResult> withAction(ImportAction action) => [
    for (final r in rows)
      if (r.action == action) r,
  ];

  List<ImportRowResult> get issues => [
    for (final r in rows)
      if (r.errors.isNotEmpty || r.warnings.isNotEmpty) r,
  ];

  @override
  List<Object?> get props => [dryRun, created, updated, unchanged, failed, sectionsCreated, rows];
}
