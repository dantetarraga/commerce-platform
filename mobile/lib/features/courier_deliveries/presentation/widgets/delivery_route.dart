import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/utils/external_links.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/orders/orders.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:flutter/material.dart';

/// Las tres paradas del recorrido sobre el trazo: tú, el negocio y el cliente.
/// La parada actual va en tarjeta con "Llamar" y "Cómo llegar".
class DeliveryRoute extends StatelessWidget {
  const DeliveryRoute({required this.order, super.key});

  final StaffOrder order;

  static Future<void> _open(BuildContext context, Future<bool> Function() launch) async {
    final opened = await launch();
    if (!opened && context.mounted) AppToast.show(context, 'No pudimos abrir esa app en este celular.');
  }

  static Future<bool> _map(GeoCoordinates at) => ExternalLinks.directions(at.latitude, at.longitude);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = context.chaski.accent;
    final o = order.order;
    final pickingUp = order.status == OrderStatus.courierAssigned;
    final distance = Formatters.meters(order.distanceMeters);
    final pickedAt = o.pickedUpAt;
    final items = '${o.itemCount} ${o.itemCount == 1 ? 'producto' : 'productos'} · código ${o.shortCode}';
    final label = AppTypography.eyebrow(context).copyWith(letterSpacing: 1);
    final place = AppTypography.displayStyle(context, size: 18, color: scheme.onSurfaceVariant);
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final you = PartnerStation(
      node: const StationNode(icon: Icons.two_wheeler_rounded, size: 40, square: true),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pickingUp ? 'TÚ · VAS AL NEGOCIO' : 'TÚ · EN CAMINO', style: label.copyWith(color: scheme.primary)),
            Text(
              pickingUp ? 'Luego llevas el pedido a $distance' : 'Por ${o.addressStreet} · $distance',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );

    final store = PartnerStation(
      node: StationNode(imageUrl: o.store.logoUrl, done: !pickingUp),
      child: pickingUp
          ? _StopCard(
              eyebrow: 'RECOGIDA',
              heading: 'Recoge el pedido',
              title: o.store.name,
              lines: [order.pickup.address, items],
              onCall: switch (order.pickup.phone) {
                final phone? => () => _open(context, () => ExternalLinks.call(phone.replaceAll(' ', ''))),
                null => null,
              },
              onMap: () => _open(context, () => _map(order.pickup.location)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pickedAt == null ? 'RECOGISTE' : 'RECOGISTE · ${Formatters.clock(pickedAt)}', style: label),
                Text(o.store.name, style: place),
                Text(items, style: muted),
              ],
            ),
    );

    final arrival = PartnerStation(
      node: StationNode(icon: Icons.home_rounded, size: 40, color: pickingUp ? scheme.outline : accent),
      child: pickingUp
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LUEGO · LLEGADA', style: label),
                Text(order.customerName, style: place),
                Text(o.addressStreet, style: muted),
              ],
            )
          : _StopCard(
              eyebrow: 'LLEGADA',
              heading: 'Entrega y cobra',
              title: order.customerName,
              lines: [o.addressStreet, if (o.addressReference.isNotEmpty) o.addressReference],
              accent: accent,
              onCall: () => _open(context, () => ExternalLinks.call(order.customerPhone)),
              onMap: () => _open(context, () => _map(order.deliveryLocation)),
            ),
    );

    return PartnerStations(stations: pickingUp ? [you, store, arrival] : [store, you, arrival]);
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
    final onCall = this.onCall;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.tileExit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(eyebrow, style: AppTypography.eyebrow(context).copyWith(color: accent ?? scheme.primary, letterSpacing: 1)),
          Text(heading, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(title, style: AppTypography.displayStyle(context, size: 20)),
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
              if (onCall != null) ...[
                Expanded(child: _StopAction(icon: Icons.call_outlined, label: 'Llamar', onTap: onCall)),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(child: _StopAction(icon: Icons.near_me_outlined, label: 'Cómo llegar', onTap: onMap)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopAction extends StatelessWidget {
  const _StopAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: AppRadius.button,
      child: InkWell(
        borderRadius: AppRadius.button,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: scheme.onPrimaryContainer),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deslizar para confirmar el paso actual: "Lo recogí" o "Entregado".
class DeliveryFooter extends StatelessWidget {
  const DeliveryFooter({required this.order, required this.busy, required this.onPickedUp, required this.onDeliver, super.key});

  final StaffOrder order;
  final bool busy;
  final VoidCallback onPickedUp;
  final VoidCallback onDeliver;

  @override
  Widget build(BuildContext context) {
    final count = order.order.itemCount;
    return PartnerContent(
      maxWidth: 720,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
        child: order.status == OrderStatus.courierAssigned
            ? SlideToConfirm(
                key: const ValueKey('pickup'),
                label: 'Lo recogí',
                hint: 'Desliza cuando tengas todo',
                detail: '$count ${count == 1 ? 'producto' : 'productos'}',
                icon: Icons.shopping_bag_outlined,
                color: Theme.of(context).colorScheme.primary,
                busy: busy,
                onConfirm: onPickedUp,
              )
            : SlideToConfirm(
                key: const ValueKey('deliver'),
                label: 'Entregado',
                hint: 'Desliza al entregar',
                detail: 'Cobras ${Formatters.money(order.order.total)}',
                icon: Icons.two_wheeler_rounded,
                color: context.chaski.accent,
                busy: busy,
                onConfirm: onDeliver,
              ),
      ),
    );
  }
}
