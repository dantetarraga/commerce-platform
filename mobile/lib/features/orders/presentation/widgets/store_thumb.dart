import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Logo del negocio en un pedido; sin logo, una tienda sobre [background].
class StoreThumb extends StatelessWidget {
  const StoreThumb({required this.url, required this.background, this.size = 48, super.key});

  final String? url;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return AppAvatar(imageUrl: url, variant: AppAvatarVariant.store, size: size, fallbackIcon: Icons.storefront_rounded);
    }
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: AppRadius.tile),
        child: Icon(Icons.storefront_rounded, size: size * 0.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
