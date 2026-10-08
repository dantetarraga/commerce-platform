import 'package:chaski/core/maps/delivery_map_data.dart';
import 'package:chaski/core/maps/location_service.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/google_delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El SDK solo pertenece al adaptador. Las pantallas no conocen sus tipos.
abstract interface class DeliveryMapAdapter {
  Widget build(BuildContext context, DeliveryMapData data);
}

/// Google Maps donde está configurado (Android); si no, el recorrido ilustrado.
final deliveryMapAdapterProvider = Provider<DeliveryMapAdapter>(
  (ref) => googleMapsSupported ? const GoogleDeliveryMapAdapter() : const IllustratedDeliveryMapAdapter(),
);

class DeliveryMap extends ConsumerWidget {
  const DeliveryMap({required this.data, super.key});

  final DeliveryMapData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(deliveryMapAdapterProvider).build(context, data);
}

class IllustratedDeliveryMapAdapter implements DeliveryMapAdapter {
  const IllustratedDeliveryMapAdapter();

  @override
  Widget build(BuildContext context, DeliveryMapData data) => _CityMap(data: data);
}

class _CityMap extends StatelessWidget {
  const _CityMap({required this.data});

  final DeliveryMapData data;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Recorrido ilustrativo de ${data.storeLabel} a ${data.destinationLabel}. La posición del repartidor no es GPS en tiempo real.',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => TweenAnimationBuilder<double>(
          tween: Tween(end: data.estimatedProgress.clamp(0.0, 1.0)),
          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.story,
          curve: AppMotion.arrive,
          builder: (context, progress, _) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final path = cityRoute(size);
            final metric = path.computeMetrics().first;
            final rider = metric.getTangentForOffset(metric.length * progress)?.position ?? Offset.zero;
            return Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _CityMapPainter(progress, showCourier: data.showCourier)),
                  ),
                ),
                Positioned(
                  left: size.width * 0.14 - 23,
                  top: size.height * 0.36 - 25,
                  child: const _MapStop(icon: Icons.storefront_rounded, label: 'Negocio', accent: false),
                ),
                Positioned(
                  right: size.width * 0.12 - 23,
                  top: size.height * 0.7 - 25,
                  child: const _MapStop(icon: Icons.home_rounded, label: 'Tu puerta', accent: false),
                ),
                if (data.showCourier)
                  Positioned(
                    left: rider.dx - 23,
                    top: rider.dy - 25,
                    child: const _MapStop(icon: Icons.moped_rounded, label: 'Reparto', accent: true),
                  ),
                Positioned(
                  left: 20,
                  top: MediaQuery.paddingOf(context).top + 68,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const BoxDecoration(color: AppColors.blanco, borderRadius: AppRadius.button),
                    child: Text(
                      'RECORRIDO ILUSTRATIVO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.piedra, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// La misma doble curva que firma la marca, ampliada a un plano de ciudad.
Path cityRoute(Size size) => Path()
  ..moveTo(size.width * 0.14, size.height * 0.36)
  ..lineTo(size.width * 0.37, size.height * 0.36)
  ..cubicTo(size.width * 0.6, size.height * 0.36, size.width * 0.34, size.height * 0.7, size.width * 0.62, size.height * 0.7)
  ..lineTo(size.width * 0.88, size.height * 0.7);

class _MapStop extends StatelessWidget {
  const _MapStop({required this.icon, required this.label, required this.accent});

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: accent ? AppColors.terracota : AppColors.blanco,
          borderRadius: AppRadius.button,
          border: Border.all(color: accent ? AppColors.blanco : AppColors.terracota700, width: 3),
          boxShadow: AppShadows.soft(Brightness.light),
        ),
        child: Icon(icon, color: accent ? AppColors.blanco : AppColors.terracota700, size: 24),
      ),
      const SizedBox(height: 3),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.tinta)),
    ],
  );
}

class _CityMapPainter extends CustomPainter {
  const _CityMapPainter(this.progress, {required this.showCourier});

  final double progress;
  final bool showCourier;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF6EDE4));
    final blocks = Paint()..color = const Color(0xFFEEDFD2);
    for (var row = -1; row < 6; row++) {
      for (var col = -1; col < 6; col++) {
        final x = col * 93.0 + (row.isOdd ? 24 : 0);
        final y = row * 91.0;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 73, 69), Radius.circular(row.isEven ? 14 : 8)), blocks);
      }
    }
    canvas.drawOval(Rect.fromLTWH(size.width * 0.67, size.height * 0.18, 100, 70), Paint()..color = AppColors.hierbaSoft);
    final path = cityRoute(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.blanco
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24,
    );
    // Capas separadas para distinguir borde, ruta y avance en el painter.
    // ignore: cascade_invocations
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD9C2B4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * (showCourier ? progress : 1)),
      Paint()
        ..color = AppColors.terracota
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    for (var d = 0.0; d < metric.length; d += 18) {
      final point = metric.getTangentForOffset(d);
      if (point != null) canvas.drawCircle(point.position, 1.5, Paint()..color = AppColors.blanco);
    }
  }

  @override
  bool shouldRepaint(_CityMapPainter oldDelegate) => progress != oldDelegate.progress || showCourier != oldDelegate.showCourier;
}
