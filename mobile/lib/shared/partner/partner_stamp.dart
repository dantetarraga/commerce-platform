import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Sello inclinado: "LISTA", "+S/ 4.50", "PARA RENDIR".
class PartnerStamp extends StatelessWidget {
  const PartnerStamp(this.text, {this.color, this.size = 13, super.key});

  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: c, width: 2),
          borderRadius: AppRadius.exit(10),
        ),
        child: Text(
          text,
          style: AppTypography.displayStyle(context, size: size, weight: FontWeight.w800, color: c, tabular: true),
        ),
      ),
    );
  }
}
