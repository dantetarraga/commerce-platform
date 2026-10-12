import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Cómo debe verse el archivo: las filas de la plantilla, con el número de fila
/// que se usa en los mensajes de error, y qué va en cada columna.
class ImportExample extends StatelessWidget {
  const ImportExample({this.showTitle = true, super.key});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final header = templateSheet.first;
    final mono = theme.textTheme.labelMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    TableCell cell(String text, {bool head = false, bool muted = false}) => TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          text,
          style: head
              ? mono?.copyWith(fontWeight: FontWeight.w700)
              : theme.textTheme.bodySmall?.copyWith(color: muted ? scheme.onSurfaceVariant : null),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text('Ejemplo', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: AppRadius.tile,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.tile,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder(horizontalInside: BorderSide(color: scheme.outlineVariant)),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
                    children: [cell(''), for (final h in header) cell(h, head: true)],
                  ),
                  for (final (i, row) in templateSheet.skip(1).indexed)
                    TableRow(children: [cell('${i + 2}', muted: true), for (final c in row) cell(c)]),
                ],
              ),
            ),
          ),
        ),
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text('Qué va en cada columna', style: theme.textTheme.titleSmall),
            children: [
              for (final column in importColumns)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: column.header,
                          style: mono?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (column.required)
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: scheme.primary),
                          ),
                        TextSpan(
                          text: '  ${column.help}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Text(
                '* Obligatorio. El orden de las columnas no importa y puedes dejar fuera las que no uses.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
