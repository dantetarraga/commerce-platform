import 'package:chaski/features/merchant_orders/domain/merchant_board.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/comanda_skeleton.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_order_card.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_rail.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Una columna del riel como pestaña del celular (una o dos columnas de comandas).
class MerchantOrdersTab extends ConsumerWidget {
  const MerchantOrdersTab({required this.board, required this.column, super.key});

  final AsyncValue<Map<MerchantBoardColumn, List<StaffOrder>>> board;
  final MerchantBoardColumn column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = 'orders-${column.name}';
    return RefreshIndicator(
      onRefresh: () => ref.refresh(merchantActiveOrdersProvider.future),
      child: AsyncValueView(
        value: board,
        onRetry: () => ref.invalidate(merchantActiveOrdersProvider),
        loading: MerchantListView(
          storageKey: '$key-loading',
          itemCount: 2,
          itemBuilder: (_, i) => ComandaSkeleton(withActions: i == 0),
        ),
        isEmpty: (board) => board[column]!.isEmpty,
        empty: MerchantListView(
          storageKey: key,
          itemCount: 1,
          itemBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: AppEmptyState(title: column.emptyTitle, message: column.emptyMessage),
          ),
        ),
        data: (board) {
          final orders = board[column]!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = PartnerLayout.columnsFor(context, constraints.maxWidth);
              return MerchantListView(
                storageKey: key,
                itemCount: (orders.length / columns).ceil(),
                itemBuilder: (_, i) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: switch (i * columns + c) {
                          final at when at < orders.length => MerchantOrderCard(key: ValueKey(orders[at].id), order: orders[at]),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Lista bajo las pestañas fijas: reserva el espacio que ocupan.
class MerchantListView extends StatelessWidget {
  const MerchantListView({required this.storageKey, required this.itemCount, required this.itemBuilder, super.key});

  /// Id estable para recordar el scroll de cada pestaña.
  final String storageKey;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: PageStorageKey(storageKey),
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
        sliver: SliverList.separated(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        ),
      ),
    ],
  );
}
