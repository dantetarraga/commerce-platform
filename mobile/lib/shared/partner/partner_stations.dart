import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Línea sólida y redondeada que une paradas o marca un recorrido.
class TrackLine extends StatelessWidget {
  const TrackLine({this.color, this.vertical = false, this.thickness = 2, super.key});

  final Color? color;
  final bool vertical;
  final double thickness;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: vertical ? thickness : double.infinity,
      height: vertical ? double.infinity : thickness,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(thickness),
      ),
    ),
  );
}

/// Una parada del recorrido: el nodo a la izquierda sobre el trazo y su contenido.
class PartnerStation {
  const PartnerStation({required this.node, required this.child});

  final Widget node;
  final Widget child;
}

/// Estaciones unidas por el trazo vertical punteado.
class PartnerStations extends StatelessWidget {
  const PartnerStations({required this.stations, this.nodeWidth = 48, this.spacing = 14, super.key});

  final List<PartnerStation> stations;
  final double nodeWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, s) in stations.indexed)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: nodeWidth,
                child: Column(
                  children: [
                    s.node,
                    if (i < stations.length - 1)
                      const Expanded(
                        child: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: TrackLine(vertical: true)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i < stations.length - 1 ? spacing : 0),
                  child: s.child,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Nodo circular con foto (salida), ícono o check.
class StationNode extends StatelessWidget {
  const StationNode({this.imageUrl, this.icon, this.color, this.size = 44, this.square = false, this.done = false, super.key});

  final String? imageUrl;
  final IconData? icon;
  final Color? color;
  final double size;
  final bool square;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    final shape = square ? AppRadius.button : BorderRadius.circular(size / 2);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: imageUrl == null ? c : null,
              borderRadius: shape,
              border: Border.all(color: imageUrl == null ? Theme.of(context).scaffoldBackgroundColor : c, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null
                ? AppNetworkImage(url: imageUrl, width: size, height: size, fallbackIcon: Icons.storefront_rounded)
                : Icon(icon, size: size * 0.45, color: AppColors.blanco),
          ),
          if (done)
            Positioned(
              right: -4,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.hierba,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                ),
                child: const Icon(Icons.check_rounded, size: 11, color: AppColors.blanco),
              ),
            ),
        ],
      ),
    );
  }
}
