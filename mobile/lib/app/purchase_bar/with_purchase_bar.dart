import 'package:apamuy/app/purchase_bar/purchase_bar.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pone la barra de compra al pie de una pantalla fuera del shell (p. ej. el detalle de
/// un negocio), sin que el feature tenga que conocerla.
class WithPurchaseBar extends StatelessWidget {
  const WithPurchaseBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(child: child),
          const SafeArea(
            top: false,
            child: PurchaseBar(padding: EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.xxs)),
          ),
        ],
      ),
    );
  }
}
