import 'package:chaski/core/maps/delivery_map_data.dart';
import 'package:chaski/shared/widgets/delivery_map.dart';
import 'package:flutter/material.dart';

/// Puente del seguimiento al proveedor de mapas intercambiable.
class RouteMap extends StatelessWidget {
  const RouteMap({required this.progress, this.showCourier = true, this.height, this.storeLabel = 'Negocio', this.destinationLabel = 'Tu puerta', super.key});
  final double progress;
  final bool showCourier;
  final double? height;
  final String storeLabel;
  final String destinationLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: DeliveryMap(
      data: DeliveryMapData(estimatedProgress: progress, showCourier: showCourier, storeLabel: storeLabel, destinationLabel: destinationLabel),
    ),
  );
}
