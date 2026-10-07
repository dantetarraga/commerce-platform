import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/weekly_schedule.dart';
import 'package:chaski/features/stores/presentation/widgets/store_mappers.dart';
import 'package:chaski/features/stores/presentation/widgets/store_stat_blocks.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Nombre, estado, quién atiende, los tres datos, la oferta y, si está
/// cerrado, la opción de programar el pedido.
class StoreHeader extends StatelessWidget {
  const StoreHeader({required this.store, required this.scheduledAt, required this.onSchedule, super.key});

  final StoreDetail store;
  final DateTime? scheduledAt;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = store.summary;
    final chaski = context.chaski;
    final now = DateTime.now();
    final open = summary.isOpenNow;
    final details = [
      if (open) ?store.schedule.closingLabel(now) else ?store.schedule.nextOpeningLabel(now),
      Formatters.distance(summary.distanceKm),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            hint: 'Ver horario y dirección',
            child: InkWell(
              borderRadius: const BorderRadius.all(AppRadius.md),
              onTap: () => _showStoreAbout(context, store),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(store.name, style: theme.textTheme.headlineLarge)),
                        const SizedBox(height: AppSpacing.xxs),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: open ? '● Abierto' : '● Cerrado',
                                style: TextStyle(color: open ? chaski.success : chaski.danger, fontWeight: FontWeight.w700),
                              ),
                              for (final d in details) TextSpan(text: '  ·  $d'),
                            ],
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.onSurfaceVariant, semanticLabel: 'Sobre el negocio'),
                ],
              ),
            ),
          ),
          if (store.attendedByLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(store.attendedByLabel!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          StoreStatBlocks(summary: summary),
          if (summary.promoLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DealStrip(label: summary.promoLabel!),
          ],
          if (!summary.deliversToYou) ...[
            const SizedBox(height: AppSpacing.sm),
            const _Note(
              icon: Icons.wrong_location_outlined,
              text: 'Este negocio no llega a tu dirección. Puedes ver la carta igual.',
            ),
          ] else if (!open) ...[
            const SizedBox(height: AppSpacing.md),
            _ClosedBlock(
              scheduledAt: scheduledAt,
              canSchedule: store.schedule.nextOpeningAt(now) != null,
              onSchedule: onSchedule,
            ),
          ],
        ],
      ),
    );
  }
}

/// Hoja "Sobre el negocio": descripción, quién atiende, horario de hoy y dirección.
void _showStoreAbout(BuildContext context, StoreDetail store) {
  final summary = store.summary;
  final today = store.schedule.hoursOn(DateTime.now());
  showAppBottomSheet<void>(
    context,
    title: store.name,
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (store.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(store.description!, style: Theme.of(context).textTheme.bodyMedium),
              ),
            if (store.attendedByLabel != null) _AboutRow(Icons.waving_hand_outlined, store.attendedByLabel!),
            if (summary.rating.hasReviews)
              _AboutRow(
                Icons.star_rounded,
                '${Formatters.rating(summary.rating.average)} de ${summary.rating.count} pedidos calificados',
              ),
            _AboutRow(
              Icons.schedule_rounded,
              today.isEmpty
                  ? 'Hoy no abre'
                  : 'Hoy: ${today.map((h) => '${Formatters.timeOfDay(h.opensAt)} – ${Formatters.timeOfDay(h.closesAt)}').join(', ')}',
            ),
            _AboutRow(Icons.place_outlined, '${store.addressLine} · a ${Formatters.distance(summary.distanceKm)}'),
            if (!summary.minOrderAmount.isZero)
              _AboutRow(Icons.shopping_bag_outlined, 'Pedido mínimo ${Formatters.money(summary.minOrderAmount)}'),
          ],
        ),
      ),
    ),
  ).ignore();
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _DealStrip extends StatelessWidget {
  const _DealStrip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaski = context.chaski;
    return Semantics(
      label: 'Oferta: $label',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(color: chaski.accentSoft, borderRadius: AppRadius.tile),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: chaski.accent, shape: BoxShape.circle),
              child: Icon(Icons.local_offer_rounded, size: 13, color: chaski.onAccent),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Negocio cerrado: en vez de un callejón sin salida, programar el pedido.
class _ClosedBlock extends StatelessWidget {
  const _ClosedBlock({required this.scheduledAt, required this.canSchedule, required this.onSchedule});

  final DateTime? scheduledAt;
  final bool canSchedule;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final at = scheduledAt;
    final (title, message) = switch ((at, canSchedule)) {
      (final at?, _) => (
        'Tu pedido va programado',
        'Te lo llevamos ${Formatters.whenPhrase(at, now: DateTime.now())}. Ya puedes armarlo.',
      ),
      (null, true) => ('Pide ahora y te lo llevamos al abrir', 'Elige la hora; te avisamos cuando salga.'),
      (null, false) => (
        'Por ahora no está atendiendo',
        'Aún no publicó su próximo horario. Puedes ver la carta igual.',
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: AppRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onInverseSurface)),
          const SizedBox(height: AppSpacing.xxs),
          Text(message, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface.withValues(alpha: 0.75))),
          if (canSchedule) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: at == null ? 'Programar pedido' : 'Cambiar hora',
              icon: Icons.schedule_rounded,
              size: AppButtonSize.md,
              onPressed: onSchedule,
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
