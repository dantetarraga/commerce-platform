import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/features/checkout/domain/delivery_slots.dart';
import 'package:apamuy/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:apamuy/features/checkout/presentation/providers/delivery_slots_provider.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja "¿Para cuándo?": los próximos días y las horas en que [storeId] atiende,
/// calculadas por el backend. [canOrderNow] ofrece volver a "lo antes posible".
Future<DateTime?> showScheduleSheet(
  BuildContext context, {
  required String storeId,
  String? storeName,
  bool canOrderNow = true,
}) {
  return showAppBottomSheet<DateTime>(
    context,
    builder: (_) => _ScheduleSheet(storeId: storeId, storeName: storeName, canOrderNow: canOrderNow, now: DateTime.now()),
  );
}

class _ScheduleSheet extends ConsumerStatefulWidget {
  const _ScheduleSheet({required this.storeId, required this.canOrderNow, required this.now, this.storeName});

  final String storeId;
  final String? storeName;
  final bool canOrderNow;
  final DateTime now;

  @override
  ConsumerState<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends ConsumerState<_ScheduleSheet> {
  DateTime? _day;
  DateTime? _selected;

  /// Al llegar las horas: el día y la hora ya elegidos si siguen valiendo, si no
  /// el primer día que atiende.
  void _start(List<DeliveryDay> days) {
    if (_day != null) return;
    final current = ref.read(checkoutControllerProvider).draft.deliveryTime;
    final chosen = current is DeliverAt ? current.at : null;
    final withChosen = days.where((d) => chosen != null && d.slots.contains(chosen)).firstOrNull;
    _day = (withChosen ?? days.where((d) => !d.isClosed).firstOrNull ?? days.firstOrNull)?.date;
    _selected = withChosen != null ? chosen : null;
  }

  void _pickDay(DateTime day) {
    HapticFeedback.selectionClick().ignore();
    setState(() {
      _day = day;
      _selected = null;
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
    return store == null ? 'Elige el día y la hora de llegada' : 'Tu pedido de $store, cuando atiende';
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(deliverySlotsProvider(widget.storeId));
    final header = AppSheetHeader(
      title: '¿Para cuándo?',
      subtitle: _subtitle,
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.md + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          switch (slots) {
            AsyncData(:final value) => _content(context, value),
            AsyncError(:final error) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: AppInlineNotice.fromError(error, onRetry: () => ref.invalidate(deliverySlotsProvider(widget.storeId))),
            ),
            _ => const SizedBox(height: 160, child: Center(child: AppLoader())),
          },
        ],
      ),
    );
  }

  Widget _content(BuildContext context, List<DeliveryDay> days) {
    _start(days);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final day = days.where((d) => d.date == _day).firstOrNull;
    final selected = _selected;
    final canGoAsap = widget.canOrderNow && ref.watch(checkoutControllerProvider.select((s) => s.draft.deliveryTime is DeliverAt));
    final noneAtAll = days.every((d) => d.isClosed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Row(
            children: [
              for (final d in days) ...[
                AppChip(
                  label: d.isClosed ? '${_dayLabel(d.date, widget.now)} · Cerrado' : _dayLabel(d.date, widget.now),
                  variant: AppChipVariant.choice,
                  selected: d.date == _day,
                  onTap: d.isClosed ? null : () => _pickDay(d.date),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (day != null && !day.isClosed)
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
                    for (final at in day.slots)
                      SizedBox(
                        width: width,
                        child: _SlotCell(at: at, selected: at == selected, onTap: () => _pickSlot(at)),
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
              noneAtAll
                  ? 'Este negocio no atiende en los próximos días.'
                  : selected == null
                  ? 'Elige una hora.'
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
    );
  }

  String _confirmLabel(DateTime at) {
    final clock = Formatters.clock(at);
    return switch (_daysFrom(widget.now, at)) {
      0 => 'Programar para las $clock',
      1 => 'Programar para mañana, $clock',
      _ => 'Programar para el ${_dayLabel(at, widget.now).toLowerCase()}, $clock',
    };
  }
}

int _daysFrom(DateTime now, DateTime at) =>
    DateTime(at.year, at.month, at.day).difference(DateTime(now.year, now.month, now.day)).inDays;

/// "Hoy" · "Mañana" · "Jue 25".
String _dayLabel(DateTime at, DateTime now) {
  const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  return switch (_daysFrom(now, at)) {
    0 => 'Hoy',
    1 => 'Mañana',
    _ => '${weekdays[at.weekday - 1]} ${at.day}',
  };
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({required this.at, required this.selected, required this.onTap});

  final DateTime at;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: Formatters.clock(at),
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
            color: selected ? scheme.primary : context.apamuy.raised,
            borderRadius: AppRadius.tile,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: Formatters.hour12(at)),
                TextSpan(
                  text: ' ${Formatters.meridiem(at)}',
                  style: TextStyle(fontSize: Theme.of(context).textTheme.labelSmall?.fontSize, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            style: AppTypography.price(context, size: 15).copyWith(color: selected ? scheme.onPrimary : scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
