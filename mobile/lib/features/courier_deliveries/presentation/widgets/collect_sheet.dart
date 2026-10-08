import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/orders.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cómo pagó el cliente y cuánto recibió (por defecto, el total). Cierra con
/// `(CollectionMethod, Money)`.
class CollectSheet extends StatefulWidget {
  const CollectSheet({required this.order, super.key});

  final StaffOrder order;

  @override
  State<CollectSheet> createState() => _CollectSheetState();
}

class _CollectSheetState extends State<CollectSheet> {
  late CollectionMethod _method = CollectionMethod.from(widget.order.order.payment);
  late final _amount = TextEditingController(text: (widget.order.order.total.cents / 100).toStringAsFixed(2));

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.order.order.total;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Total del pedido', style: theme.textTheme.bodyMedium),
            Text(Formatters.money(total), style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.md),
            Text('Medio de pago recibido', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final m in CollectionMethod.values)
                  AppChip(label: m.label, selected: m == _method, onTap: () => setState(() => _method = m)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder(
              valueListenable: _amount,
              builder: (context, value, _) {
                final amount = Money.tryParse(value.text);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppInput(
                      label: 'Monto recibido (S/)',
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      errorText: amount == null ? 'Escribe un monto válido' : null,
                    ),
                    if (amount != null && amount != total) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'No coincide con el total (${Formatters.money(total)}). Se registrará igual.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Confirmar entrega',
                      onPressed: amount == null
                          ? null
                          : () {
                              HapticFeedback.mediumImpact().ignore();
                              Navigator.of(context).pop((_method, amount));
                            },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
