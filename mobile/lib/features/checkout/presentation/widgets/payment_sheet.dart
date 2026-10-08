import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:apamuy/features/checkout/presentation/widgets/payment_brand.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja "¿Cómo pagas?". Guarda la elección en el checkout al tocar "Usar …".
Future<void> showPaymentSheet(BuildContext context, {required Money total}) => showAppBottomSheet<void>(
  context,
  builder: (_) => _PaymentSheet(total: total),
);

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.total});

  final Money total;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late PaymentKind _kind;
  Money? _changeFor;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(checkoutControllerProvider).draft;
    _kind = draft.paymentKind ?? PaymentKind.yape;
    _changeFor = draft.cashChangeFor;
  }

  void _select(PaymentKind kind) {
    if (kind == _kind) return;
    HapticFeedback.selectionClick().ignore();
    setState(() => _kind = kind);
  }

  void _confirm() {
    final controller = ref.read(checkoutControllerProvider.notifier)..setPayment(_kind);
    if (_kind == PaymentKind.cash) controller.setCashChange(_changeFor);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: '¿Cómo pagas?',
            subtitle: 'Pagas cuando te llega: ${Formatters.money(widget.total)}',
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
          ),
          for (final kind in PaymentKind.offered) ...[
            _PaymentOption(kind: kind, selected: _kind == kind, onTap: () => _select(kind)),
            if (kind == PaymentKind.cash)
              AnimatedSize(
                duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
                curve: AppMotion.arrive,
                alignment: Alignment.topCenter,
                child: _kind == PaymentKind.cash
                    ? _CashChange(
                        total: widget.total,
                        bills: suggestedBills(widget.total),
                        value: _changeFor,
                        onChanged: (v) {
                          HapticFeedback.selectionClick().ignore();
                          setState(() => _changeFor = v);
                        },
                      )
                    : const SizedBox(width: double.infinity),
              ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: _kind.useLabel, onPressed: _confirm),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({required this.kind, required this.selected, required this.onTap});

  final PaymentKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${kind.label}. ${kind.hint}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : context.apamuy.raised,
          borderRadius: const BorderRadius.all(AppRadius.lg),
          border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 1.5),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: const BorderRadius.all(AppRadius.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  _Radio(selected: selected),
                  const SizedBox(width: AppSpacing.sm),
                  PaymentLogo(kind),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kind.label, style: theme.textTheme.titleSmall),
                        Text(kind.hint, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? scheme.primary : scheme.outline, width: selected ? 7 : 2),
      ),
    );
  }
}

/// "¿Con cuánto pagas?" → billetes y el vuelto que llevará el repartidor.
class _CashChange extends StatelessWidget {
  const _CashChange({required this.total, required this.bills, required this.value, required this.onChanged});

  final Money total;
  final List<Money> bills;
  final Money? value;
  final ValueChanged<Money?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paysWith = value;
    final change = cashChange(paysWith, total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Con cuánto pagas?', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppChip(label: 'Exacto', variant: AppChipVariant.choice, selected: paysWith == null, onTap: () => onChanged(null)),
              for (final bill in bills)
                AppChip(
                  label: Formatters.money(bill),
                  variant: AppChipVariant.choice,
                  selected: paysWith == bill,
                  onTap: () => onChanged(bill),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            change == null ? 'Ten el monto exacto a mano.' : 'Te llevamos ${Formatters.money(change)} de vuelto.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: change == null ? theme.colorScheme.onSurfaceVariant : context.apamuy.success,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
