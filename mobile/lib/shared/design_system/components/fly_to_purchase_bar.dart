import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

/// El traspaso: la foto del producto viaja desde [from] hasta la barra de compra (abajo,
/// al centro) encogiéndose, como el chaski que entrega el mensaje.
///
/// [from] es el rectángulo global de origen (p. ej. la foto del detalle).
/// Con movimiento reducido no hace nada.
Future<void> flyToPurchaseBar(BuildContext context, {required Rect from, String? imageUrl}) async {
  if (reduceMotionOf(context)) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  final size = MediaQuery.sizeOf(context);
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  final to = Rect.fromCenter(center: Offset(size.width / 2, size.height - bottomInset - 60), width: 36, height: 36);

  final controller = AnimationController(vsync: Navigator.of(context), duration: AppMotion.move + const Duration(milliseconds: 120));
  final entry = OverlayEntry(
    builder: (_) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = AppMotion.arrive.transform(controller.value);
        // Arco: sube un poco antes de caer hacia la barra de compra.
        final rect = Rect.lerp(from, to, t)!;
        final lift = -80 * (1 - (2 * t - 1) * (2 * t - 1));
        return Positioned(
          left: rect.left,
          top: rect.top + lift,
          width: rect.width,
          height: rect.height,
          child: IgnorePointer(
            child: Opacity(
              opacity: (1.2 - t).clamp(0.0, 1.0),
              child: AppNetworkImage(
                url: imageUrl,
                width: rect.width,
                height: rect.height,
                borderRadius: BorderRadius.circular(AppRadius.lg.x * (1 - t) + 18 * t),
                fallbackIcon: Icons.fastfood_rounded,
              ),
            ),
          ),
        );
      },
    ),
  );
  overlay.insert(entry);
  try {
    await controller.forward();
  } finally {
    entry.remove();
    controller.dispose();
  }
}

/// Rectángulo global de un widget (por su [GlobalKey]).
Rect? globalRectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
