import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/domain/merchant.dart';
import 'package:chaski/features/merchant_orders/domain/merchant_board.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/comanda_skeleton.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_order_card.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/store_switch.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Título y texto vacío de cada columna del riel (también las pestañas del celular).
extension MerchantBoardColumnText on MerchantBoardColumn {
  String get title => switch (this) {
    MerchantBoardColumn.fresh => 'Nuevas',
    MerchantBoardColumn.cooking => 'En fogón',
    MerchantBoardColumn.ready => 'Listas',
  };

  String get emptyTitle => switch (this) {
    MerchantBoardColumn.fresh => 'Sin comandas nuevas',
    MerchantBoardColumn.cooking => 'Nada en el fogón',
    MerchantBoardColumn.ready => 'Nada esperando repartidor',
  };

  String get emptyMessage => switch (this) {
    MerchantBoardColumn.fresh => 'Te avisaremos con una alarma cuando llegue la siguiente.',
    MerchantBoardColumn.cooking => 'Las comandas que aceptes aparecen aquí hasta que estén listas.',
    MerchantBoardColumn.ready => 'Aquí sigues la recogida y la entrega de lo que ya salió.',
  };

  Color dot(BuildContext context) => switch (this) {
    MerchantBoardColumn.fresh => Theme.of(context).colorScheme.primary,
    MerchantBoardColumn.cooking => Theme.of(context).colorScheme.onSurface,
    MerchantBoardColumn.ready => context.chaski.accent,
  };
}

/// Cabecera en barra del riel de la tablet: logo, titular, comandas de hoy,
/// interruptor del negocio y acciones.
class RailHero extends ConsumerWidget {
  const RailHero({required this.store, required this.eyebrow, required this.actions, super.key});

  final MerchantStore? store;
  final String eyebrow;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = this.store;
    return PartnerPageHeader(
      leading: PartnerStoreLogo(url: store?.logoUrl),
      eyebrow: '$eyebrow · ${(store?.name ?? 'Riel de comandas').toUpperCase()}',
      title: 'Tu cocina, ',
      accent: 'al toque.',
      titleSize: 28,
      trailing: [
        const _TodayCount(),
        const SizedBox(width: AppSpacing.xs),
        if (store != null)
          SizedBox(width: 270, child: StoreSwitch(store: store, compact: true))
        else if (ref.watch(merchantStoresProvider.select((s) => s.isLoading)))
          const SizedBox(width: 270, child: PartnerStatusPillSkeleton()),
        ...actions,
      ],
    );
  }
}

class _TodayCount extends ConsumerWidget {
  const _TodayCount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = ref.watch(merchantSummaryProvider).value;
    return Container(
      constraints: const BoxConstraints(minWidth: 110, minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.button),
      child: summary == null
          ? const Skeleton(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [SkeletonBox(width: 60, height: 9), SizedBox(height: 6), SkeletonBox(width: 80)],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comandas hoy', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                Text('${summary.totalCount} · ${Formatters.money(summary.sales)}', style: AppTypography.price(context, size: 18)),
              ],
            ),
    );
  }
}

/// Las tres barras de la cocina con sus comandas colgadas.
class RailBoard extends ConsumerWidget {
  const RailBoard({required this.board, super.key});

  final AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>> board;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () => ref.refresh(merchantActiveOrdersProvider.future),
    child: AsyncValueView(
      value: board,
      onRetry: () => ref.invalidate(merchantActiveOrdersProvider),
      loading: _RailRow(
        scrollable: false,
        builder: (column) => PartnerRail(
          title: column.title,
          dot: column.dot(context),
          children: [ComandaSkeleton(withActions: column == MerchantBoardColumn.fresh)],
        ),
      ),
      data: (board) => _RailRow(
        builder: (column) {
          final orders = board[column]!;
          return PartnerRail(
            title: column.title,
            count: orders.length,
            dot: column.dot(context),
            empty: _RailEmpty(column.emptyTitle),
            children: [for (final o in orders) MerchantOrderCard(key: ValueKey(o.id), order: o)],
          );
        },
      ),
    ),
  );
}

/// Las tres columnas lado a lado, bajo las pestañas fijas.
class _RailRow extends StatelessWidget {
  const _RailRow({required this.builder, this.scrollable = true});

  final Widget Function(MerchantBoardColumn column) builder;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: scrollable ? const PageStorageKey('rails') : null,
    physics: scrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
    slivers: [
      SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xl),
        sliver: SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final column in MerchantBoardColumn.values) ...[
                if (column.index > 0) const SizedBox(width: 20),
                Expanded(child: builder(column)),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class _RailEmpty extends StatelessWidget {
  const _RailEmpty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
