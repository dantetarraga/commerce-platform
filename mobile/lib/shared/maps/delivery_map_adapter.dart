import 'package:apamuy/core/maps/delivery_map_data.dart';
import 'package:flutter/widgets.dart';

/// El SDK solo pertenece al adaptador. Las pantallas no conocen sus tipos.
abstract interface class DeliveryMapAdapter {
  Widget build(BuildContext context, DeliveryMapData data);
}
