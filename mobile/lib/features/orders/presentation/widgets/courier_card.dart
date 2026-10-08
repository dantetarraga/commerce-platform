import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Quién lleva el pedido, con atajos para escribirle o llamarle.
class CourierCard extends StatelessWidget {
  const CourierCard({required this.courier, super.key});

  final Courier courier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.xxs, AppSpacing.xs),
      decoration: BoxDecoration(color: context.apamuy.raised, borderRadius: AppRadius.card),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: courier.avatarUrl,
            initials: courier.initials,
            seed: courier.name,
            variant: AppAvatarVariant.courier,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courier.name, style: theme.textTheme.titleSmall),
                Text(
                  [courier.vehicle, if (courier.since != null) 'Reparte en Espinar desde ${courier.since}'].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppCircleButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Escribir a ${courier.firstName}',
            onPressed: () => AppToast.show(context, 'Muy pronto: mensajes con ${courier.firstName} sin salir de la app.'),
          ),
          AppCircleButton(
            icon: Icons.call_rounded,
            tooltip: 'Llamar a ${courier.firstName}',
            onPressed: () => AppToast.show(context, 'Muy pronto: llamadas sin compartir tu número.'),
          ),
        ],
      ),
    );
  }
}
