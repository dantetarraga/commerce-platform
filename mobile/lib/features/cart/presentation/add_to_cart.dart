import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/features/cart/domain/entities/cart.dart';
import 'package:chaski/features/cart/presentation/providers/cart_providers.dart';
import 'package:chaski/features/cart/presentation/widgets/cart_sheet.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agrega a la bolsa desde cualquier pantalla: resuelve el conflicto de negocio
/// preguntando, vibra y avisa. `true` si el producto quedó en la bolsa.
Future<bool> addToCart(BuildContext context, WidgetRef ref, {required CartLine line, required CartStore store}) async {
  final controller = ref.read(cartControllerProvider.notifier);
  final result = await controller.add(line, store);
  if (!context.mounted) return false;
  switch (result) {
    case Added():
      HapticFeedback.lightImpact().ignore();
      AppToast.show(context, '${line.name} va en tu bolsa', kind: AppToastKind.success);
      return true;
    case StoreConflict(:final current, :final incoming):
      final replace = await confirmReplaceCart(context, current: current, incoming: incoming);
      if (!replace || !context.mounted) return false;
      await controller.replaceWith(line, store);
      if (!context.mounted) return true;
      HapticFeedback.lightImpact().ignore();
      AppToast.show(context, 'Empezamos una bolsa nueva en ${incoming.name}', kind: AppToastKind.success);
      return true;
  }
}

/// Línea para el "+" rápido (productos sin variantes ni opciones).
CartLine quickCartLine({required String productId, required String name, required Money price, String? imageUrl}) => CartLine(
  id: '$productId.${DateTime.now().microsecondsSinceEpoch}',
  productId: productId,
  name: name,
  imageUrl: imageUrl,
  unitPrice: price,
  quantity: Quantity.one,
);
