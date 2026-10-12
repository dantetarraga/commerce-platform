import 'dart:async';

import 'package:apamuy/features/courier_deliveries/domain/location_sharing.dart';
import 'package:apamuy/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Por qué hace falta la ubicación y cómo darla, si falta durante un pedido.
class LocationSharingNotice extends ConsumerWidget {
  const LocationSharingNotice({this.padding = EdgeInsets.zero, super.key});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(courierLocationSharingProvider);
    final notice = switch (status) {
      CourierLocationStatus.denied => (
        'Sin tu ubicación, el cliente no te ve llegar en el mapa. Solo se comparte mientras llevas un pedido.',
        'Permitir ubicación',
      ),
      CourierLocationStatus.blocked => (
        'La ubicación está bloqueada para Apamuy Socios. Actívala en Ajustes > Permisos > Ubicación para que el cliente te vea llegar.',
        'Abrir ajustes',
      ),
      CourierLocationStatus.gpsOff => (
        'Tu GPS está apagado: el cliente no te ve llegar en el mapa.',
        'Activar GPS',
      ),
      CourierLocationStatus.idle || CourierLocationStatus.sharing => null,
    };
    if (notice == null) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: AppInlineNotice(
        kind: AppNoticeKind.warning,
        message: notice.$1,
        actionLabel: notice.$2,
        onAction: () => unawaited(ref.read(courierLocationSharingProvider.notifier).fix()),
      ),
    );
  }
}
