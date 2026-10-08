import 'package:apamuy/core/maps/delivery_location.dart';
import 'package:apamuy/features/addresses/addresses.dart';
import 'package:apamuy/features/discovery/discovery.dart';
import 'package:apamuy/features/notifications/notifications.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Entregar en · Jr. Tacna 248 ▾"; abre la hoja de direcciones.
class HomeAddressPill extends ConsumerWidget {
  const HomeAddressPill({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final address = ref.watch(selectedAddressProvider);
    final here = ref.watch(currentDeliveryLocationProvider.select((l) => l.label));
    final label = address?.street ?? here;
    return AppTapSurface(
      semanticLabel: 'Entregar en $label. Cambiar dirección',
      color: compact ? Colors.transparent : scheme.surface,
      borderRadius: AppRadius.tileExit,
      pressScale: 1,
      clip: false,
      onTap: () => showAddressPicker(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 0 : 7, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: scheme.primary, borderRadius: AppRadius.button),
                child: Icon(address == null ? Icons.near_me_rounded : addressIcon(address.kind), size: 18, color: scheme.onPrimary),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact) Text('Entregar en', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall)),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: scheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campana de avisos con punto si hay sin leer.
class HomeBell extends ConsumerWidget {
  const HomeBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final unread = ref.watch(unreadNoticesCountProvider);
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: unread == 0 ? 'Avisos' : 'Avisos, $unread sin leer',
        onPressed: () => context.pushNamed(NotificationsPage.name),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(unread == 0 ? Icons.notifications_none_rounded : Icons.notifications_rounded, color: scheme.onSurface),
            if (unread > 0)
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Barra sobre el seguimiento: dirección y ayuda con el pedido.
class HomeOrderBar extends StatelessWidget {
  const HomeOrderBar({this.onHelp, super.key});

  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 10, AppSpacing.gutter, 6),
      child: Row(
        children: [
          const Expanded(child: Align(alignment: Alignment.centerLeft, child: HomeAddressPill())),
          const SizedBox(width: 12),
          if (onHelp != null)
            Material(
              color: scheme.surface,
              borderRadius: AppRadius.tileExit,
              child: InkWell(
                borderRadius: AppRadius.tileExit,
                onTap: onHelp,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline_rounded, size: 20, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text('Ayuda', style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Barra compacta al hacer scroll: dirección, buscar y avisos.
class HomeCompactBar extends StatelessWidget {
  const HomeCompactBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.md, 8),
      child: Row(
        children: [
          const Expanded(child: Align(alignment: Alignment.centerLeft, child: HomeAddressPill(compact: true))),
          const SizedBox(width: 8),
          Material(
            color: scheme.primary,
            borderRadius: AppRadius.button,
            child: IconButton(
              tooltip: 'Buscar',
              onPressed: () => context.goNamed(ExplorePage.name),
              icon: Icon(Icons.search_rounded, color: scheme.onPrimary),
            ),
          ),
          const SizedBox(width: 8),
          const HomeBell(),
        ],
      ),
    );
  }
}
