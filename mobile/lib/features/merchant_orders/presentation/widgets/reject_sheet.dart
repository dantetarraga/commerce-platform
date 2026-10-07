import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Motivo del rechazo (el cliente lo lee). Cierra con el texto final.
class RejectSheet extends StatefulWidget {
  const RejectSheet({super.key});

  @override
  State<RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<RejectSheet> {
  final _detail = TextEditingController();
  String? _reason;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  /// "Sin stock: Pollo entero" · "Cocina llena" · el texto libre si no eligió.
  String? _result(String text) {
    final detail = text.trim();
    if (_reason == null) return detail.length >= 3 ? detail : null;
    return detail.isEmpty ? _reason : '$_reason: $detail';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final r in rejectReasons)
                  AppChip(label: r, selected: r == _reason, onTap: () => setState(() => _reason = _reason == r ? null : r)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: _reason == 'Sin stock' ? '¿Qué producto falta?' : 'Detalle (opcional)',
              controller: _detail,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'El cliente verá este motivo.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder(
              valueListenable: _detail,
              builder: (context, value, _) {
                final result = _result(value.text);
                return AppButton.danger(
                  label: 'Rechazar pedido',
                  onPressed: result == null ? null : () => Navigator.of(context).pop(result),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
