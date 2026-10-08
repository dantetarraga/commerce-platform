import 'package:apamuy/features/checkout/domain/checkout.dart';
import 'package:apamuy/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hora programada del checkout (null = lo antes posible; una pasada también).
/// Negocio y producto la leen para dejar armar un pedido aunque esté cerrado.
final scheduledDeliveryProvider = Provider<DateTime?>((ref) {
  final time = ref.watch(checkoutControllerProvider.select((s) => s.draft.deliveryTime));
  return switch (time) {
    DeliverAt(:final at) when at.isAfter(DateTime.now()) => at,
    _ => null,
  };
});
