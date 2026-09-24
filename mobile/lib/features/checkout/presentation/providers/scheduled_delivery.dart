import 'package:chaski/features/checkout/domain/checkout.dart';
import 'package:chaski/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hora programada de entrega elegida en el checkout (null = lo antes posible).
///
/// Negocio y producto la leen para permitir armar un pedido programado aunque
/// el negocio esté cerrado ahora. Sale del borrador del checkout: una hora que
/// ya pasó cuenta como "lo antes posible".
final scheduledDeliveryProvider = Provider<DateTime?>((ref) {
  final time = ref.watch(checkoutControllerProvider.select((s) => s.draft.deliveryTime));
  return switch (time) {
    DeliverAt(:final at) when at.isAfter(DateTime.now()) => at,
    _ => null,
  };
});
