import 'package:chaski/app/posta/posta_bar.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pone la posta al pie de una pantalla fuera del shell (p. ej. el detalle de
/// un negocio), sin que el feature tenga que conocerla.
class WithPosta extends StatelessWidget {
  const WithPosta({required this.child, super.key});

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
            child: PostaBar(padding: EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.xxs)),
          ),
        ],
      ),
    );
  }
}
