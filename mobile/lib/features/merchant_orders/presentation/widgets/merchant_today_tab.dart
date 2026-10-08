import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/merchant_orders/presentation/providers/merchant_providers.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/merchant_orders_tab.dart';
import 'package:chaski/features/merchant_orders/presentation/widgets/today_charts.dart';
import 'package:chaski/features/orders/orders_staff.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Hoy": lo vendido, las gráficas del día (calculadas por el backend) y la
/// lista de pedidos.
class MerchantTodayTab extends ConsumerWidget {
  const MerchantTodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(merchantSummaryProvider)
          ..invalidate(merchantTodayOrdersProvider);
        await ref.read(merchantTodayOrdersProvider.future);
      },
      child: AsyncValueView(
        value: ref.watch(merchantTodayOrdersProvider),
        onRetry: () => ref.invalidate(merchantTodayOrdersProvider),
        loading: MerchantListView(
          storageKey: 'today-loading',
          itemCount: 4,
          itemBuilder: (_, i) => i == 0 ? const _MetricsSkeleton() : const _TodayRowSkeleton(),
        ),
        data: (orders) => MerchantListView(
          storageKey: 'today',
          itemCount: orders.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TodayMetrics(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Pedidos de hoy', style: theme.textTheme.titleLarge),
                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.md),
                      child: Text('Todavía no hay pedidos hoy.'),
                    ),
                ],
              );
            }
            return _TodayRow(order: orders[index - 1]);
          },
        ),
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PartnerSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffOrderHeader(order: order),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              Text(order.customerName, style: theme.textTheme.bodyMedium),
              Text(Formatters.money(order.order.subtotal), style: theme.textTheme.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayMetrics extends ConsumerWidget {
  const _TodayMetrics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AsyncValueView(
      value: ref.watch(merchantSummaryProvider),
      compactError: true,
      onRetry: () => ref.invalidate(merchantSummaryProvider),
      loading: const _MetricsSkeleton(),
      data: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TodayHeadline(summary: summary),
          const SizedBox(height: AppSpacing.md),
          if (summary.salesByHour.isEmpty)
            Text(
              'Las gráficas aparecen con la primera entrega del día.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else ...[
            TodayChartCard(
              title: 'Ventas por hora',
              subtitle: 'Lo vendido en cada hora, en soles',
              child: SalesByHourChart(hours: summary.salesByHour, peakHour: summary.peakHour),
            ),
            const SizedBox(height: AppSpacing.md),
            TodayChartCard(
              title: 'Cómo te pagaron',
              subtitle: 'Lo que cobra el repartidor al entregar',
              child: PaymentsBar(payments: summary.payments),
            ),
            if (summary.topProducts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              TodayChartCard(
                title: 'Lo más pedido',
                subtitle: 'Unidades vendidas hoy',
                child: TopProductsChart(products: summary.topProducts),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: AppRadius.card),
    child: const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 90),
          SizedBox(height: 10),
          SkeletonBox(width: 150, height: 34),
          SizedBox(height: AppSpacing.md),
          Row(children: [SkeletonBox(width: 90), SizedBox(width: AppSpacing.lg), SkeletonBox(width: 90)]),
        ],
      ),
    ),
  );
}

class _TodayRowSkeleton extends StatelessWidget {
  const _TodayRowSkeleton();

  @override
  Widget build(BuildContext context) => const PartnerSurface(
    child: Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [SkeletonBox(width: 80, height: 22), SizedBox(width: AppSpacing.xs), SkeletonBox(width: 70, height: 20)]),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: 120, height: 12),
          SizedBox(height: 10),
          Row(children: [SkeletonBox(width: 110), SizedBox(width: AppSpacing.lg), SkeletonBox(width: 60)]),
        ],
      ),
    ),
  );
}
