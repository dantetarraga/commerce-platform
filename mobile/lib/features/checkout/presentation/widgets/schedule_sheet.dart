import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja "¿Para cuándo?": día y hora cada 15 min. [notBefore] es la primera hora
/// posible (p. ej. cuando abre el negocio); la elección queda en el checkout.
Future<DateTime?> showScheduleSheet(BuildContext context, {String? storeName, DateTime? notBefore}) {
  return showAppBottomSheet<DateTime>(
    context,
    builder: (_) => _ScheduleSheet(storeName: storeName, notBefore: notBefore, now: DateTime.now()),
  );
}

class _ScheduleSheet extends ConsumerStatefulWidget {
  const _ScheduleSheet({required this.now, this.storeName, this.notBefore});

  final String? storeName;
  final DateTime? notBefore;
  final DateTime now;

  @override
  ConsumerState<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends ConsumerState<_ScheduleSheet> {
  static const _days = 3;

  late final DateTime _first = firstSchedulable(widget.now, notBefore: widget.notBefore);
  late DateTime _day;
  DateTime? _selected;

  List<DateTime> get _dayOptions {
    final today = _dateOnly(widget.now);
    return [for (var i = 0; i < _days; i++) DateTime(today.year, today.month, today.day + i)];
  }

  List<ScheduleSlot> _slotsFor(DateTime day) =>
      scheduleSlots(widget.now, day: day, notBefore: widget.notBefore, count: 16);

  @override
  void initState() {
    super.initState();
    // Arranca en lo ya elegido (si sigue valiendo) o en la primera hora posible.
    final current = ref.read(checkoutControllerProvider).draft.deliveryTime;
    final chosen = current is DeliverAt && !current.at.isBefore(_first) ? current.at : null;
    final start = chosen ?? _first;
    final options = _dayOptions;
    _day = options.lastWhere((d) => !d.isAfter(start), orElse: () => options.first);
    _selected = _slotsFor(_day).where((s) => s.available && (chosen == null || s.at == chosen)).firstOrNull?.at;
  }

  void _pickDay(DateTime day) {
    HapticFeedback.selectionClick().ignore();
    setState(() {
      _day = day;
      _selected = _slotsFor(day).where((s) => s.available).firstOrNull?.at;
    });
  }

  void _pickSlot(DateTime at) {
    HapticFeedback.selectionClick().ignore();
    setState(() => _selected = at);
  }

  void _confirm() {
    final at = _selected;
    if (at == null) return;
    ref.read(checkoutControllerProvider.notifier).setDeliveryTime(DeliverAt(at));
    Navigator.of(context).pop(at);
  }

  void _asap() {
    ref.read(checkoutControllerProvider.notifier).setDeliveryTime(const DeliverAsap());
    Navigator.of(context).pop();
  }

  String get _subtitle {
    final store = widget.storeName;
    final opens = widget.notBefore;
    if (store != null && opens != null && opens.isAfter(widget.now)) {
      return '$store abre ${Formatters.whenPhrase(opens, now: widget.now)}';
    }
    if (store != null) return 'Tu pedido de $store, a la hora que te acomode';
    return 'Elige el día y la hora de llegada';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final slots = _slotsFor(_day);
    final hasAvailable = slots.any((s) => s.available);
    final selected = _selected;
    final canGoAsap = widget.notBefore == null && ref.watch(checkoutControllerProvider.select((s) => s.draft.deliveryTime is DeliverAt));

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.md + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: '¿Para cuándo?',
            subtitle: _subtitle,
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Row(
              children: [
                for (final day in _dayOptions) ...[
                  AppChip(
                    label: _scheduleDay(day, widget.now).label,
                    variant: AppChipVariant.choice,
                    selected: day == _day,
                    onTap: () => _pickDay(day),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const columns = 4;
                const gap = AppSpacing.xs;
                final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final slot in slots)
                      SizedBox(
                        width: width,
                        child: _SlotCell(
                          slot: slot,
                          selected: slot.at == selected,
                          onTap: slot.available ? () => _pickSlot(slot.at) : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: AnimatedSwitcher(
              duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
              child: Text(
                key: ValueKey(selected),
                selected == null
                    ? (hasAvailable ? 'Elige una hora.' : 'Ese día ya no alcanzamos. Prueba otro día.')
                    : 'Llega entre ${Formatters.hour12(selected)} y '
                          '${Formatters.clock(selected.add(const Duration(minutes: deliveryWindowMinutes)))}. '
                          'Puedes cancelar hasta que empiecen a prepararlo.',
                style: muted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: selected == null ? 'Elige una hora' : _confirmLabel(selected),
                  onPressed: selected == null ? null : _confirm,
                ),
                if (canGoAsap) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppButton.ghost(label: 'Mejor lo antes posible', expand: true, onPressed: _asap),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _confirmLabel(DateTime at) {
    final day = _scheduleDay(at, widget.now);
    final clock = Formatters.clock(at);
    return switch (day.offset) {
      0 => 'Programar para las $clock',
      1 => 'Programar para mañana, $clock',
      _ => 'Programar para el ${day.label.toLowerCase()}, $clock',
    };
  }
}

DateTime _dateOnly(DateTime at) => DateTime(at.year, at.month, at.day);

/// Día de la grilla: cuántos faltan desde hoy y su etiqueta ("Hoy" · "Mañana" · "Jue 25").
({int offset, String label}) _scheduleDay(DateTime at, DateTime now) {
  const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final offset = _dateOnly(at).difference(_dateOnly(now)).inDays;
  final label = switch (offset) {
    0 => 'Hoy',
    1 => 'Mañana',
    _ => '${weekdays[at.weekday - 1]} ${at.day}',
  };
  return (offset: offset, label: label);
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({required this.slot, required this.selected, required this.onTap});

  final ScheduleSlot slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = slot.available;
    final fg = selected
        ? scheme.onPrimary
        : available
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.32);
    final label = Formatters.hour12(slot.at);
    return Semantics(
      button: available,
      selected: selected,
      enabled: available,
      label: available ? Formatters.clock(slot.at) : '${Formatters.clock(slot.at)}, no disponible',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
          curve: AppMotion.arrive,
          height: AppSpacing.minTouch,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : (available ? context.apamuy.raised : Colors.transparent),
            borderRadius: AppRadius.tile,
            border: available ? null : Border.all(color: scheme.outlineVariant),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: ' ${Formatters.meridiem(slot.at)}',
                  style: TextStyle(fontSize: Theme.of(context).textTheme.labelSmall?.fontSize, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            style: AppTypography.price(context, size: 15).copyWith(
              color: fg,
              decoration: available ? null : TextDecoration.lineThrough,
              decorationColor: fg,
            ),
          ),
        ),
      ),
    );
  }
}
