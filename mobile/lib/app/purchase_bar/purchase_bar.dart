import 'package:apamuy/app/purchase_bar/open_bag.dart';
import 'package:apamuy/app/purchase_bar/purchase_bar_controller.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La barra de compra conectada al estado de la app (bolsa / pedido en curso).
/// Se coloca sobre la barra de navegación y en las pantallas de detalle.
class PurchaseBar extends ConsumerWidget {
  const PurchaseBar({this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm), super.key});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseBar = ref.watch(purchaseBarProvider);
    return Padding(
      padding: padding,
      child: AppPurchaseBar(
        state: purchaseBar.state,
        pulse: purchaseBar.pulse,
        onTap: () => openPurchaseBar(context, ref),
      ),
    );
  }
}
