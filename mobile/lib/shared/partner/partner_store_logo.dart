import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Logo del negocio en círculo con borde claro (cabecera del riel, tarjetas de
/// recojo). Decorativo: no se lee con lector de pantalla.
class PartnerStoreLogo extends StatelessWidget {
  const PartnerStoreLogo({this.url, this.size = 56, this.borderWidth = 3, this.borderColor, super.key});

  final String? url;
  final double size;
  final double borderWidth;

  /// Por defecto, `colorScheme.surface`.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? Theme.of(context).colorScheme.surface, width: borderWidth),
      ),
      child: AppNetworkImage(
        url: url,
        width: size,
        height: size,
        borderRadius: BorderRadius.all(Radius.circular(size / 2)),
        fallbackIcon: Icons.storefront_rounded,
      ),
    ),
  );
}
