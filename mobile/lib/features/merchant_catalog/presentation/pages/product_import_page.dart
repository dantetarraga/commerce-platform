import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/spreadsheet_reader.dart';
import 'package:apamuy/features/merchant_catalog/presentation/providers/menu_providers.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/import_example.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/menu_page_scaffold.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carga masiva de la carta desde un Excel o CSV: primero revisa el archivo y
/// muestra qué haría; al confirmar, guarda todo junto. Igual que en la web.
class ProductImportPage extends ConsumerStatefulWidget {
  const ProductImportPage({required this.storeId, super.key});

  static const name = 'productImport';
  final String storeId;

  @override
  ConsumerState<ProductImportPage> createState() => _ProductImportPageState();
}

final class _Preview {
  const _Preview({required this.fileName, required this.rows, required this.ignoredColumns, required this.result});

  final String fileName;
  final List<ImportRow> rows;
  final List<String> ignoredColumns;
  final ImportResult result;
}

const _templateName = 'plantilla-carta-apamuy.csv';

class _ProductImportPageState extends ConsumerState<ProductImportPage> with PartnerActionRunner {
  _Preview? _preview;
  String? _fileError;
  var _templateSaved = false;

  MenuActions get _actions => ref.read(menuActionsProvider.notifier);

  Future<void> _saveTemplate() async {
    try {
      final saved = await FilePicker.saveFile(
        fileName: _templateName,
        bytes: templateCsv(templateSheet),
        mimeType: 'text/csv',
      );
      if (saved != null && mounted) setState(() => _templateSaved = true);
    } on Exception {
      if (mounted) AppToast.show(context, 'No pudimos guardar la plantilla.', kind: AppToastKind.error);
    }
  }

  Future<void> _pickFile() async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['xlsx', 'csv']);
    } on Exception {
      setState(() => _fileError = 'No pudimos abrir tus archivos.');
      return;
    }
    if (file == null || !mounted) return;
    setState(() => _fileError = null);
    final picked = file;
    await run(() async {
      final parsed = switch (await _actions.readImportFile(await picked.readAsBytes(), picked.name)) {
        Ok(:final value) => value,
        Err(:final failure) => () {
          _fileError = failure.message;
          return null;
        }(),
      };
      switch (parsed) {
        case null:
          return null;
        case SheetProblem(:final message):
          _fileError = message;
          return null;
        case SheetRows(:final rows, :final ignoredColumns):
          switch (await _actions.importProducts(widget.storeId, rows, dryRun: true)) {
            case Ok(:final value):
              _preview = _Preview(fileName: picked.name, rows: rows, ignoredColumns: ignoredColumns, result: value);
              return null;
            case Err(:final failure):
              return failure;
          }
      }
    });
  }

  Future<void> _confirm() async {
    final preview = _preview!;
    final ok = await run(
      () async => switch (await _actions.importProducts(widget.storeId, preview.rows, dryRun: false)) {
        Ok() => null,
        Err(:final failure) => failure,
      },
      success: 'Carta actualizada: ${preview.result.created} nuevos y ${preview.result.updated} actualizados.',
    );
    if (ok && mounted) {
      ref.read(importHighlightsProvider.notifier).set(preview.result.rows);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return MenuPageScaffold(
      title: preview == null ? 'Importar ' : 'Revisa ',
      accent: preview == null ? 'productos.' : 'antes de guardar.',
      bottom: preview == null
          ? AppButton(
              label: busy ? 'Revisando…' : 'Elegir archivo',
              icon: Icons.upload_file_rounded,
              loading: busy,
              onPressed: busy ? null : _pickFile,
            )
          : Row(
              children: [
                AppButton.secondary(
                  label: 'Otro archivo',
                  expand: false,
                  onPressed: busy ? null : () => setState(() => _preview = null),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: switch (preview.result) {
                      ImportResult(failed: > 0) => 'Corrige el archivo',
                      ImportResult(pending: 0) => 'No hay cambios',
                      ImportResult(pending: 1) => 'Guardar 1 producto',
                      final r => 'Guardar ${r.pending} productos',
                    },
                    loading: busy,
                    onPressed: busy || preview.result.failed > 0 || preview.result.pending == 0 ? null : _confirm,
                  ),
                ),
              ],
            ),
      body: preview == null
          ? _FileSteps(
              templateSaved: _templateSaved,
              error: _fileError,
              onSaveTemplate: busy ? null : _saveTemplate,
            )
          : _Review(preview: preview),
    );
  }
}

enum _StepState { done, active, next }

class _FileSteps extends StatelessWidget {
  const _FileSteps({required this.templateSaved, required this.error, required this.onSaveTemplate});

  final bool templateSaved;
  final String? error;
  final VoidCallback? onSaveTemplate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
      children: [
        _StepCard(
          number: 1,
          state: templateSaved ? _StepState.done : _StepState.active,
          title: templateSaved ? 'Plantilla guardada' : 'Guarda la plantilla',
          message: templateSaved
              ? '$_templateName. Ábrela en Excel o Google Sheets.'
              : 'Ábrela en Excel o Google Sheets, o en el celular con la app de hojas de cálculo.',
          child: templateSaved
              ? null
              : AppButton.secondary(
                  label: 'Guardar plantilla',
                  icon: Icons.download_rounded,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: onSaveTemplate,
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepCard(
          number: 2,
          state: templateSaved ? _StepState.active : _StepState.next,
          title: 'Una fila por producto',
          message: 'Solo nombre y precio son obligatorios. Si el producto ya está en tu carta, se actualiza.',
          child: const ImportExample(showTitle: false),
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepCard(
          number: 3,
          state: _StepState.next,
          title: 'Súbela y revisa',
          message: 'Como .xlsx o .csv. Nada se guarda hasta que confirmes.',
          child: error == null ? null : AppInlineNotice(message: error!, kind: AppNoticeKind.error),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.state,
    required this.title,
    required this.message,
    this.child,
  });

  final int number;
  final _StepState state;
  final String title;
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final apamuy = context.apamuy;
    final active = state == _StepState.active;
    final (Color badge, Color onBadge) = switch (state) {
      _StepState.done => (apamuy.success, Colors.white),
      _StepState.active => (scheme.primary, scheme.onPrimary),
      _StepState.next => (scheme.surface, scheme.onSurfaceVariant),
    };
    return Semantics(
      container: true,
      label: switch (state) {
        _StepState.done => 'Paso $number, listo',
        _StepState.active => 'Paso $number, ahora',
        _StepState.next => 'Paso $number',
      },
      child: Material(
        color: state == _StepState.next ? apamuy.raised : apamuy.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.tile,
          side: BorderSide(
            color: active ? scheme.primary : (state == _StepState.done ? scheme.outlineVariant : Colors.transparent),
            width: active ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: badge,
                  foregroundColor: onBadge,
                  child: state == _StepState.done
                      ? const Icon(Icons.check_rounded, size: 18)
                      : Text('$number', style: AppTypography.price(context, size: 15).copyWith(color: onBadge)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    if (child != null) ...[const SizedBox(height: AppSpacing.sm), child!],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.preview});

  final _Preview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final apamuy = context.apamuy;
    final result = preview.result;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final errors = result.withAction(ImportAction.error);
    final warnings = [
      for (final r in result.rows)
        if (r.action != ImportAction.error && r.warnings.isNotEmpty) r,
    ];
    final updated = result.withAction(ImportAction.update);
    final created = result.withAction(ImportAction.create);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
      children: [
        Text('Revisamos ${preview.fileName}. Todavía no se guardó nada.', style: muted),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Total(
                  value: result.created,
                  label: result.created == 1 ? 'nuevo' : 'nuevos',
                  color: scheme.secondaryContainer,
                  onColor: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _Total(
                  value: result.updated,
                  label: result.updated == 1 ? 'cambia' : 'cambian',
                  color: scheme.primaryContainer,
                  onColor: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: result.failed > 0
                    ? _Total(
                        value: result.failed,
                        label: 'con error',
                        color: scheme.errorContainer,
                        onColor: scheme.onErrorContainer,
                      )
                    : _Total(
                        value: result.sectionsCreated.length,
                        label: result.sectionsCreated.length == 1 ? 'sección nueva' : 'secciones nuevas',
                        color: apamuy.raised,
                        onColor: scheme.onSurface,
                      ),
              ),
            ],
          ),
        ),
        if (result.unchanged > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.unchanged == 1 ? '1 producto queda igual.' : '${result.unchanged} productos quedan igual.',
            style: muted,
          ),
        ],
        if (errors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _RowGroup(
            title: 'Corrige estas filas y vuelve a elegir el archivo',
            rows: [
              for (final row in errors) _Line(title: _rowTitle(row), notes: row.errors, notesColor: scheme.error),
            ],
          ),
        ],
        for (final row in warnings) ...[
          const SizedBox(height: AppSpacing.sm),
          AppInlineNotice(message: '${_rowTitle(row)}: ${row.warnings.join(' ')}', kind: AppNoticeKind.warning),
        ],
        if (updated.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _RowGroup(
            title: 'Cambian',
            rows: [
              for (final row in updated)
                _Line(
                  title: row.name,
                  trailing: _ChangeSummary(row: row),
                ),
            ],
          ),
        ],
        if (created.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _RowGroup(
            title: 'Nuevos',
            rows: [
              for (final row in created)
                _Line(
                  title: row.name,
                  trailing: row.priceTo == null
                      ? null
                      : Text(Formatters.money(row.priceTo!), style: theme.textTheme.titleSmall),
                ),
            ],
          ),
        ],
        if (result.sectionsCreated.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Secciones nuevas: ${result.sectionsCreated.join(', ')}.', style: theme.textTheme.bodyMedium),
        ],
        if (preview.ignoredColumns.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Columnas que no se usan: ${preview.ignoredColumns.join(', ')}.', style: muted),
        ],
      ],
    );
  }

  static String _rowTitle(ImportRowResult row) =>
      row.name.isEmpty ? 'Fila ${row.line}' : 'Fila ${row.line} · ${row.name}';
}

class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label, required this.color, required this.onColor});

  final int value;
  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: AppRadius.tile),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: AppTypography.price(context, size: 24).copyWith(color: onColor)),
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: onColor)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Precio de antes tachado y el nuevo; si no cambia el precio, qué cambia.
class _ChangeSummary extends StatelessWidget {
  const _ChangeSummary({required this.row});

  final ImportRowResult row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final others = [
      for (final c in row.changes)
        if (c != ImportChange.price) c.label,
    ];
    final from = row.priceFrom;
    final to = row.priceTo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (from != null && to != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: Formatters.money(from),
                  style: TextStyle(color: muted, decoration: TextDecoration.lineThrough),
                ),
                const TextSpan(text: '  '),
                TextSpan(
                  text: Formatters.money(to),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            semanticsLabel: 'De ${Formatters.money(from)} a ${Formatters.money(to)}',
            style: theme.textTheme.bodyMedium,
          ),
        if (others.isNotEmpty) Text(others.join(', '), style: theme.textTheme.bodySmall?.copyWith(color: muted)),
      ],
    );
  }
}

final class _Line {
  const _Line({required this.title, this.trailing, this.notes = const [], this.notesColor});

  final String title;
  final Widget? trailing;
  final List<String> notes;
  final Color? notesColor;
}

/// Un grupo de filas de la revisión; los largos muestran los primeros y un
/// botón para ver todos.
class _RowGroup extends StatefulWidget {
  const _RowGroup({required this.title, required this.rows});

  final String title;
  final List<_Line> rows;

  @override
  State<_RowGroup> createState() => _RowGroupState();
}

class _RowGroupState extends State<_RowGroup> {
  static const _preview = 5;
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = widget.rows;
    final shown = _all ? rows : rows.take(_preview).toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.apamuy.card,
        borderRadius: AppRadius.tile,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: theme.textTheme.titleSmall)),
                Text('${rows.length}', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          for (final line in shown) ...[
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.title, style: theme.textTheme.bodyMedium),
                        for (final note in line.notes)
                          Text(note, style: theme.textTheme.bodySmall?.copyWith(color: line.notesColor)),
                      ],
                    ),
                  ),
                  if (line.trailing != null) ...[const SizedBox(width: AppSpacing.sm), line.trailing!],
                ],
              ),
            ),
          ],
          if (rows.length > _preview) ...[
            Divider(height: 1, color: scheme.outlineVariant),
            TextButton(
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all ? 'Ver menos' : 'Ver los ${rows.length}'),
            ),
          ],
        ],
      ),
    );
  }
}
