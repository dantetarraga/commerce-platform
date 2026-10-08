import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/merchant_orders/domain/merchant.dart';
import 'package:apamuy/features/merchant_orders/domain/merchant_board.dart';
import 'package:apamuy/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:apamuy/features/merchant_orders/presentation/widgets/merchant_order_card.dart';
import 'package:apamuy/features/merchant_orders/presentation/widgets/order_card_skeleton.dart';
import 'package:apamuy/features/merchant_orders/presentation/widgets/store_switch.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:apamuy/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Título y texto vacío de cada columna del riel (también las pestañas del celular).
extension MerchantBoardColumnText on MerchantBoardColumn {
  String get title => switch (this) {
    MerchantBoardColumn.fresh => 'Nuevos',
    MerchantBoardColumn.cooking => 'Preparando',
    MerchantBoardColumn.ready => 'Listos',
  };

  String get emptyTitle => switch (this) {
    MerchantBoardColumn.fresh => 'Sin pedidos nuevos',
    MerchantBoardColumn.cooking => 'Nada en preparación',
    MerchantBoardColumn.ready => 'Nada por entregar',
  };

  AppEmptyArt get emptyArt => switch (this) {
    MerchantBoardColumn.fresh => AppEmptyArt.bell,
    MerchantBoardColumn.cooking => AppEmptyArt.flame,
    MerchantBoardColumn.ready => AppEmptyArt.takeout,
  };

  String get emptyMessage => switch (this) {
    MerchantBoardColumn.fresh => 'Te avisamos con la alarma apenas llegue uno.',
    MerchantBoardColumn.cooking => 'Cuando aceptes un pedido, lo verás aquí.',
    MerchantBoardColumn.ready => 'Los pedidos que marques listos esperan aquí al repartidor.',
  };

  Color dot(BuildContext context) => switch (this) {
    MerchantBoardColumn.fresh => Theme.of(context).colorScheme.primary,
    MerchantBoardColumn.cooking => Theme.of(context).colorScheme.onSurface,
    MerchantBoardColumn.ready => context.apamuy.accent,
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
      eyebrow: '$eyebrow · ${(store?.name ?? 'Tus pedidos').toUpperCase()}',
      title: 'Tu negocio, ',
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
                Text('Pedidos hoy', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                Text('${summary.totalCount} · ${Formatters.money(summary.sales)}', style: AppTypography.price(context, size: 18)),
              ],
            ),
    );
  }
}

/// Las tres barras de la cocina con sus comandas colgadas.
class RailBoard extends ConsumerWidget {
  const RailBoard({required this.board, super.key});

  final AsyncValue<MerchantBoard> board;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () => ref.refresh(merchantBoardProvider.future),
    child: AsyncValueView(
      value: board,
      onRetry: () => ref.invalidate(merchantBoardProvider),
      loading: _RailRow(
        scrollable: false,
        builder: (column) => PartnerRail(
          title: column.title,
          dot: column.dot(context),
          children: [OrderCardSkeleton(withActions: column == MerchantBoardColumn.fresh)],
        ),
      ),
      data: (board) => _RailRow(
        builder: (column) {
          final orders = board[column].items;
          return PartnerRail(
            title: column.title,
            count: orders.length,
            dot: column.dot(context),
            empty: MerchantColumnEmpty(column: column, compact: true),
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

/// Una columna sin comandas: su ícono, qué va ahí y un dato del momento
/// (la tienda recibiendo, los nuevos que esperan, lo entregado hoy).
class MerchantColumnEmpty extends ConsumerWidget {
  const MerchantColumnEmpty({required this.column, this.compact = false, super.key});

  final MerchantBoardColumn column;

  /// En el riel de la tablet: más chico y sin saltar de pestaña.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = switch (column) {
      MerchantBoardColumn.fresh => switch (ref.watch(merchantStoresProvider).value) {
        final stores? when stores.isNotEmpty => stores.any((s) => s.isAcceptingOrders)
            ? const AppEmptyChip(label: 'Recibiendo pedidos · alarma lista', live: true)
            : const AppEmptyChip(label: 'Pedidos en pausa'),
        _ => null,
      },
      MerchantBoardColumn.cooking => switch (ref.watch(merchantBoardProvider).value?[MerchantBoardColumn.fresh].count) {
        final waiting? when waiting > 0 => AppEmptyChip(
          label: '$waiting ${waiting == 1 ? 'pedido espera' : 'pedidos esperan'} respuesta${compact ? '' : ' →'}',
          onTap: compact ? null : () => DefaultTabController.maybeOf(context)?.animateTo(MerchantBoardColumn.fresh.index),
        ),
        _ => null,
      },
      MerchantBoardColumn.ready => switch (ref.watch(merchantSummaryProvider).value?.deliveredCount) {
        final delivered? when delivered > 0 => AppEmptyChip(label: 'Hoy entregaste $delivered'),
        _ => null,
      },
    };
    return AppEmptyState(
      scene: column.emptyArt,
      title: column.emptyTitle,
      message: column.emptyMessage,
      extra: extra,
      compact: compact,
    );
  }
}
