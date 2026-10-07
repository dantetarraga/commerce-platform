import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/features/courier_deliveries/presentation/widgets/collect_sheet.dart';
import 'package:chaski/features/courier_deliveries/presentation/widgets/collect_ticket.dart';
import 'package:chaski/features/courier_deliveries/presentation/widgets/delivery_route.dart';
import 'package:chaski/features/courier_deliveries/presentation/widgets/delivery_skeleton.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El pedido que lleva el repartidor, en dos pasos: recoger en el negocio y
/// entregar al cliente cobrando contraentrega.
class ActiveDeliveryPage extends ConsumerStatefulWidget {
  const ActiveDeliveryPage({required this.orderId, super.key});

  static const name = 'activeDelivery';

  final String orderId;

  @override
  ConsumerState<ActiveDeliveryPage> createState() => _ActiveDeliveryPageState();
}

class _ActiveDeliveryPageState extends ConsumerState<ActiveDeliveryPage> with PartnerActionRunner {
  /// El pedido que se está entregando: se sigue mostrando mientras la página
  /// se cierra, aunque el provider ya no lo tenga en curso.
  StaffOrder? _delivering;

  Future<void> _pickedUp(StaffOrder order) => run(() => ref.read(courierActionsProvider.notifier).pickedUp(order.id));

  Future<void> _deliver(StaffOrder order) async {
    final collected = await showAppBottomSheet<(CollectionMethod, Money)>(
      context,
      title: '¿Cómo pagó ${order.customerName.split(' ').first}?',
      builder: (_) => SingleChildScrollView(child: CollectSheet(order: order)),
    );
    if (collected == null || !mounted) return;
    final (method, amount) = collected;
    setState(() => _delivering = order);
    final ok = await run(() => ref.read(courierActionsProvider.notifier).delivered(order.id, method: method, amount: amount));
    if (!mounted) return;
    if (!ok) {
      setState(() => _delivering = null);
      return;
    }
    AppToast.show(context, 'Entregado. ¡Buen trabajo!', kind: AppToastKind.success, leading: const AppRiveSuccess(size: 40));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(courierActiveDeliveryProvider);
    final delivering = _delivering;
    return Scaffold(
      appBar: partnerStatusBar(context),
      body: AsyncValueView(
        value: delivering != null ? AsyncData<StaffOrder?>(delivering) : delivery,
        onRetry: () => ref.invalidate(courierActiveDeliveryProvider),
        loading: const DeliverySkeleton(),
        isEmpty: (order) => order == null || order.id != widget.orderId,
        empty: const AppEmptyState(title: 'Este pedido ya no está en curso', message: 'Vuelve al inicio para ver otros.'),
        data: (order) => _content(order!),
      ),
    );
  }

  Widget _content(StaffOrder order) {
    final pickingUp = order.status == OrderStatus.courierAssigned;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          PartnerPageHeader(
            eyebrow: 'RECORRIDO ${order.order.code} · PASO ${pickingUp ? 1 : 2} DE 2',
            title: pickingUp ? 'Recógelo, ' : 'Llévalo, ',
            accent: 'al toque.',
            metricLabel: pickingUp ? 'Entrega a' : 'Llegada a',
            metric: Formatters.meters(order.distanceMeters),
          ),
          Expanded(
            child: PartnerContent(
              maxWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.lg),
                children: [
                  DeliveryRoute(order: order),
                  const SizedBox(height: AppSpacing.lg),
                  CollectTicket(order: order),
                ],
              ),
            ),
          ),
          DeliveryFooter(
            order: order,
            busy: busy,
            onPickedUp: () => _pickedUp(order),
            onDeliver: () => _deliver(order),
          ),
        ],
      ),
    );
  }
}
