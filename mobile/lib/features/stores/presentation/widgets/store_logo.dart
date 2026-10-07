import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Logo del negocio: mosaico con sombra montado sobre el borde de la portada.
/// Sin [logoUrl] y con [loading], muestra el esqueleto.
class StoreLogo extends StatelessWidget {
  const StoreLogo({this.logoUrl, this.loading = false, super.key});

  static const size = 68.0;

  final String? logoUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const inner = BorderRadius.all(Radius.circular(13));
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(AppRadius.lg),
        boxShadow: AppShadows.raised(theme.brightness),
      ),
      child: loading
          ? const Skeleton(child: SkeletonBox(borderRadius: inner, height: size - 6))
          : AppNetworkImage(url: logoUrl, borderRadius: inner, fallbackIcon: Icons.storefront_rounded),
    );
  }
}
