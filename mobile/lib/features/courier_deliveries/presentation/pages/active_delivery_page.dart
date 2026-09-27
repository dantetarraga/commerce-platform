import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/external_links.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:chaski/shared/widgets/partner_brand.dart';
import 'package:chaski/shared/widgets/partner_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ActiveDeliveryPageState extends ConsumerState<ActiveDeliveryPage> {
  var _busy = false;

  Future<void> _pickedUp(StaffOrder order) async {
    setState(() => _busy = true);
    final failure = await ref.read(courierActionsProvider.notifier).pickedUp(order.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) AppToast.show(context, failure.message, kind: AppToastKind.error);
  }

  Future<void> _deliver(StaffOrder order) async {
    final collected = await showAppBottomSheet<(CollectionMethod, Money)>(
      context,
      title: '¿Cómo pagó ${order.customerName.split(' ').first}?',
      builder: (_) => SingleChildScrollView(child: _CollectSheet(order: order)),
    );
    if (collected == null || !mounted) return;
    setState(() => _busy = true);
    final (method, amount) = collected;
    final failure = await ref.read(courierActionsProvider.notifier).delivered(order.id, method: method, amount: amount);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      AppToast.show(context, failure.message, kind: AppToastKind.error);
      return;
    }
    AppToast.show(
      context,
      'Entregado. ¡Buen trabajo!',
      kind: AppToastKind.success,
      leading: const AppRiveSuccess(size: 40),
    );
    Navigator.of(context).pop();
  }

  Future<void> _open(Future<bool> Function() launch) async {
    final opened = await launch();
    if (!opened && mounted) AppToast.show(context, 'No pudimos abrir esa app en este celular.');
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(courierActiveDeliveryProvider);
    return Scaffold(
      appBar: partnerStatusBar(context),
      body: AsyncValueView(
        value: delivery,
        onRetry: () => ref.invalidate(courierActiveDeliveryProvider),
        loading: const Center(child: CircularProgressIndicator()),
        isEmpty: (order) => order == null || order.id != widget.orderId,
        empty: const AppEmptyState(
          title: 'Este pedido ya no está en curso',
          message: 'Vuelve al inicio para ver otros.',
        ),
        data: (order) => _content(context, order!),
      ),
    );
  }

  Widget _content(BuildContext context, StaffOrder order) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pickingUp = order.status == OrderStatus.courierAssigned;
    final meters = order.distanceMeters;
    final distance = meters < 1000 ? '$meters m' : Formatters.distance(meters / 1000);
    final pickedAt = order.order.events.where((e) => e.status == OrderStatus.onTheWay).map((e) => e.at).firstOrNull;
    final code = order.order.code.replaceAll('#', '');
    final label = theme.textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800);
    final place = TextStyle(fontFamily: AppTypography.display, fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface, height: 1.2);
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final you = PartnerStation(
      node: const StationNode(icon: Icons.two_wheeler_rounded, size: 40, square: true),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pickingUp ? 'TÚ · VAS AL NEGOCIO' : 'TÚ · EN CAMINO', style: label?.copyWith(color: scheme.primary)),
            Text(
              pickingUp ? 'Luego llevas el pedido a $distance' : 'Por ${order.order.addressStreet} · $distance',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );

    final storeCard = PartnerStation(
      node: StationNode(imageUrl: order.order.store.logoUrl, done: !pickingUp),
      child: pickingUp
          ? _StopCard(
              eyebrow: 'RECOGIDA',
              heading: 'Recoge el pedido',
              title: order.order.store.name,
              lines: [order.pickup.address, '${order.order.itemCount} productos · código $code'],
              onCall: order.pickup.phone == null ? null : () => _open(() => ExternalLinks.call(order.pickup.phone!.replaceAll(' ', ''))),
              onMap: () => _open(() => _map(order.pickup.location)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickedAt == null ? 'RECOGISTE' : 'RECOGISTE · ${Formatters.clock(pickedAt)}',
                  style: label?.copyWith(color: scheme.onSurfaceVariant),
                ),
                Text(order.order.store.name, style: place.copyWith(color: scheme.onSurfaceVariant)),
                Text('${order.order.itemCount} productos · código $code', style: muted),
              ],
            ),
    );

    final arrival = PartnerStation(
      node: StationNode(icon: Icons.home_rounded, size: 40, color: pickingUp ? scheme.outline : AppColors.hierba),
      child: pickingUp
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LUEGO · LLEGADA', style: label?.copyWith(color: scheme.onSurfaceVariant)),
                Text(order.customerName, style: place.copyWith(color: scheme.onSurfaceVariant)),
                Text(order.order.addressStreet, style: muted),
              ],
            )
          : _StopCard(
              eyebrow: 'LLEGADA',
              heading: 'Entrega y cobra',
              title: order.customerName,
              lines: [order.order.addressStreet, if (order.order.addressReference.isNotEmpty) order.order.addressReference],
              accent: AppColors.hierba,
              onCall: () => _open(() => ExternalLinks.call(order.customerPhone)),
              onMap: () => _open(() => _map(order.deliveryLocation)),
            ),
    );

    return SafeArea(
      top: false,
      child: Column(
        children: [
          _DeliveryHeader(code: order.order.code, pickingUp: pickingUp, distance: distance),
          Expanded(
            child: PartnerContent(
              maxWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.lg),
                children: [
                  PartnerStations(
                    stations: pickingUp ? [you, storeCard, arrival] : [storeCard, you, arrival],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _CollectTicket(order: order),
                ],
              ),
            ),
          ),
          PartnerContent(
            maxWidth: 720,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
              child: pickingUp
                  ? SlideToConfirm(
                      key: const ValueKey('pickup'),
                      label: 'Lo recogí',
                      hint: 'Desliza cuando tengas todo',
                      detail: '${order.order.itemCount} productos',
                      icon: Icons.shopping_bag_outlined,
                      color: scheme.primary,
                      busy: _busy,
                      onConfirm: () => _pickedUp(order),
                    )
                  : SlideToConfirm(
                      key: const ValueKey('deliver'),
                      label: 'Entregado',
                      hint: 'Desliza al entregar',
                      detail: 'Cobras ${Formatters.money(order.order.total)}',
                      icon: Icons.two_wheeler_rounded,
                      color: AppColors.hierba,
                      busy: _busy,
                      onConfirm: () => _deliver(order),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool> _map(GeoCoordinates at) => ExternalLinks.map(at.latitude, at.longitude);
}

/// "RECORRIDO #3104 · Llévalo, al toque." con la distancia a la derecha.
class _DeliveryHeader extends StatelessWidget {
  const _DeliveryHeader({required this.code, required this.pickingUp, required this.distance});

  final String code;
  final bool pickingUp;
  final String distance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 16),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(backgroundColor: scheme.surface, fixedSize: const Size.square(44)),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECORRIDO $code · PASO ${pickingUp ? 1 : 2} DE 2',
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer, letterSpacing: 1.2, fontWeight: FontWeight.w800),
                ),
                Text.rich(
                  TextSpan(
                    text: pickingUp ? 'Recógelo, ' : 'Llévalo, ',
                    children: [TextSpan(text: 'al toque.', style: TextStyle(color: scheme.primary))],
                  ),
                  style: TextStyle(fontFamily: AppTypography.display, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1, color: scheme.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(pickingUp ? 'Entrega a' : 'Llegada a', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              Text(distance, style: AppTypography.price(context, size: 22)),
            ],
          ),
        ],
      ),
    );
  }
}

/// La parada actual: a dónde ir y cómo contactar.
class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.eyebrow,
    required this.heading,
    required this.title,
    required this.lines,
    required this.onMap,
    this.onCall,
    this.accent,
  });

  final String eyebrow;
  final String heading;
  final String title;
  final List<String> lines;
  final VoidCallback onMap;
  final VoidCallback? onCall;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;
    Widget action(IconData icon, String text, VoidCallback onTap) => Expanded(
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.button,
        child: InkWell(
          borderRadius: AppRadius.button,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: scheme.onPrimaryContainer),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.tileExit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(eyebrow, style: theme.textTheme.labelSmall?.copyWith(color: color, letterSpacing: 1, fontWeight: FontWeight.w800)),
          Text(heading, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontFamily: AppTypography.display, fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface, height: 1.2),
          ),
          for (final (i, line) in lines.indexed)
            Text(
              line,
              style: i == 0
                  ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
                  : theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onCall != null) ...[action(Icons.call_outlined, 'Llamar', onCall!), const SizedBox(width: 8)],
              action(Icons.near_me_outlined, 'Cómo llegar', onMap),
            ],
          ),
        ],
      ),
    );
  }
}

/// Boleta de lo que lleva y lo que cobra al entregar.
class _CollectTicket extends StatelessWidget {
  const _CollectTicket({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final o = order.order;
    final payment = o.payment;
    final change = payment is CashPayment && payment.changeFor != null ? Money(payment.changeFor!.cents - o.total.cents) : null;
    final row = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant);
    final item = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    final eyebrow = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 1.2, fontWeight: FontWeight.w800);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketEdge(top: true),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('LO QUE LLEVAS', style: eyebrow),
              for (final line in o.lines) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${line.quantity}×  ', style: item?.copyWith(color: scheme.primary)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.name, style: item),
                          if (line.notes.isNotEmpty)
                            Text('“${line.notes}”', style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (o.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Nota: ${o.notes}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        const TicketPerforation(),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('COBRA AL ENTREGAR', style: eyebrow)),
                  Text(payment.label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 6),
              LeaderRow(label: Text('Pedido', style: row), value: Text(Formatters.money(Money(o.total.cents - o.deliveryFee.cents)), style: row)),
              const SizedBox(height: 4),
              LeaderRow(label: Text('Envío', style: row), value: Text(Formatters.money(o.deliveryFee), style: row)),
              const SizedBox(height: 6),
              LeaderRow(
                label: Text('Total', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                value: Text(Formatters.money(o.total), style: AppTypography.price(context, size: 28)),
              ),
              if (change != null && change.cents > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Paga con ${Formatters.money((payment as CashPayment).changeFor!)} · lleva ${Formatters.money(change)} de vuelto',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
        const TicketEdge(top: false),
      ],
    );
  }
}

/// Cómo pagó el cliente y cuánto recibió (por defecto, el total).
class _CollectSheet extends StatefulWidget {
  const _CollectSheet({required this.order});

  final StaffOrder order;

  @override
  State<_CollectSheet> createState() => _CollectSheetState();
}

class _CollectSheetState extends State<_CollectSheet> {
  late CollectionMethod _method = CollectionMethod.from(
    widget.order.order.payment,
  );
  late final _amount = TextEditingController(
    text: (widget.order.order.total.cents / 100).toStringAsFixed(2),
  );

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Money? get _parsed {
    final value = double.tryParse(_amount.text.replaceAll(',', '.').trim());
    if (value == null || !value.isFinite || value < 0) return null;
    return Money((value * 100).round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = _parsed;
    final total = widget.order.order.total;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Total del pedido', style: theme.textTheme.bodyMedium),
            Text(Formatters.money(total), style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.md),
            Text('Medio de pago recibido', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final m in CollectionMethod.values)
                  AppChip(
                    label: m.label,
                    selected: m == _method,
                    onTap: () => setState(() => _method = m),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: 'Monto recibido (S/)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: amount == null ? 'Escribe un monto válido' : null,
            ),
            if (amount != null && amount != total) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No coincide con el total (${Formatters.money(total)}). Se registrará igual.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Confirmar entrega',
              onPressed: amount == null
                  ? null
                  : () {
                      HapticFeedback.mediumImpact().ignore();
                      Navigator.of(context).pop((_method, amount));
                    },
            ),
          ],
        ),
      ),
    );
  }
}
