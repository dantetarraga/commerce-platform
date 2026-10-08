import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Propina en la boleta: S/ 1 · 2 · 3 · Otro. Tocar la elegida la quita.
class TipSelector extends StatelessWidget {
  const TipSelector({required this.value, required this.onChanged, super.key});

  final Money value;
  final ValueChanged<Money> onChanged;

  bool get _isCustom => !value.isZero && !tipPresets.contains(value);

  void _pick(Money tip) {
    HapticFeedback.selectionClick().ignore();
    onChanged(value == tip ? const Money.zero() : tip);
  }

  Future<void> _custom(BuildContext context) async {
    final tip = await _askCustomTip(context, initial: _isCustom ? value : null);
    if (tip == null) return;
    HapticFeedback.selectionClick().ignore();
    onChanged(tip);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Propina para el repartidor',
      child: Row(
        children: [
          for (final preset in tipPresets) ...[
            Expanded(
              child: _TipChip(
                label: 'S/ ${preset.cents ~/ 100}',
                selected: value == preset,
                onTap: () => _pick(preset),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: _TipChip(
              label: _isCustom ? Formatters.money(value) : 'Otro',
              selected: _isCustom,
              onTap: () => _custom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 48 de área táctil con 40 visibles.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.arrive,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.primary : context.ticketInk,
              borderRadius: AppRadius.button,
            ),
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: AppTypography.price(context, size: 15).copyWith(color: selected ? scheme.onPrimary : scheme.onSurface),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs), child: Text(label)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Money?> _askCustomTip(BuildContext context, {Money? initial}) {
  return showAppBottomSheet<Money>(
    context,
    title: 'Otra propina',
    subtitle: 'Va completa para quien te lo lleva.',
    builder: (_) => _CustomTipForm(initial: initial),
  );
}

class _CustomTipForm extends StatefulWidget {
  const _CustomTipForm({this.initial});

  final Money? initial;

  @override
  State<_CustomTipForm> createState() => _CustomTipFormState();
}

class _CustomTipFormState extends State<_CustomTipForm> {
  late final _text = TextEditingController(
    text: widget.initial == null ? '' : (widget.initial!.cents / 100).toStringAsFixed(2),
  );
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = Money.tryParse(_text.text);
    if (amount == null) {
      setState(() => _error = 'Escribe un monto, por ejemplo 4.50');
      return;
    }
    if (maxTip < amount) {
      setState(() => _error = 'Hasta ${Formatters.money(maxTip)}');
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            label: 'Monto en soles',
            controller: _text,
            hint: '4.50',
            autofocus: true,
            prefixIcon: Icons.volunteer_activism_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            errorText: _error,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Dar propina', onPressed: _submit),
        ],
      ),
    );
  }
}
