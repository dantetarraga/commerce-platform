import 'package:apamuy/core/maps/delivery_map_data.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:apamuy/shared/maps/delivery_map_adapter.dart';
import 'package:apamuy/shared/maps/google_delivery_map.dart';
import 'package:apamuy/shared/maps/illustrated_delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'delivery_map_adapter.dart';

/// Google Maps donde está configurado (Android); si no, el recorrido ilustrado.
final deliveryMapAdapterProvider = Provider<DeliveryMapAdapter>(
  (ref) => googleMapsSupported ? const GoogleDeliveryMapAdapter() : const IllustratedDeliveryMapAdapter(),
);

class DeliveryMap extends ConsumerWidget {
  const DeliveryMap({required this.data, super.key});

  final DeliveryMapData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(deliveryMapAdapterProvider).build(context, data);
}
