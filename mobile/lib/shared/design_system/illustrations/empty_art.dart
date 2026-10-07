import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

/// Arte de los estados vacíos: animaciones Lottie planas en la paleta de la
/// marca (`assets/animations/empty/`, procedencia en su README). Si una no
/// carga, se muestra su ícono en un medallón terracota con el pedido verde.
enum AppEmptyArt {
  /// Bolsa vacía (carrito sin productos).
  emptyBag(Icons.shopping_bag_outlined, 1.35),

  /// Sin conexión.
  cut(Icons.wifi_off_rounded, 0.87),

  /// Algo falló.
  tangle(Icons.error_outline_rounded, 1.25),

  /// Sin resultados.
  search(Icons.search_off_rounded, 1),

  /// Listo, pedido confirmado.
  knot(Icons.check_rounded, 0.73),

  /// Dirección, entregado.
  door(Icons.location_on_outlined, 1.35),

  /// Sin pedidos todavía.
  receipt(Icons.receipt_long_outlined, 1.3);

  const AppEmptyArt(this.icon, this.lottieScale);

  final IconData icon;

  /// Cada animación trae su propio encuadre: esto las iguala en tamaño.
  final double lottieScale;

  String get lottieAsset => 'assets/animations/empty/$name.json';
}

/// Dibuja un [AppEmptyArt]. La animación se reproduce una vez y queda en su
/// último cuadro; con movimiento reducido aparece ya en ese cuadro.
class EmptyArtView extends StatefulWidget {
  const EmptyArtView(this.art, {this.size = 160, super.key});

  final AppEmptyArt art;
  final double size;

  @override
  State<EmptyArtView> createState() => _EmptyArtViewState();
}

class _EmptyArtViewState extends State<EmptyArtView> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  void _onLoaded(LottieComposition composition) {
    _controller.duration = composition.duration;
    if (reduceMotionOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.art;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: Transform.scale(
          scale: art.lottieScale,
          child: Lottie.asset(
            art.lottieAsset,
            key: ValueKey(art),
            controller: _controller,
            onLoaded: _onLoaded,
            errorBuilder: (_, _, _) => Transform.scale(
              scale: 1 / art.lottieScale,
              child: _Medallion(art: art, size: widget.size, animate: !reduceMotionOf(context)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.art, required this.size, required this.animate});

  final AppEmptyArt art;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disc = size * 0.72;
    final dot = size * 0.13;
    Widget circle = Container(
      width: disc,
      height: disc,
      decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
      child: Icon(art.icon, size: disc * 0.46, color: scheme.primary),
    );
    // El pedido: el punto verde del logo, arriba a la derecha.
    Widget order = Container(
      width: dot,
      height: dot,
      decoration: BoxDecoration(
        color: AppColors.hierba,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: dot * 0.18),
      ),
    );
    if (animate) {
      circle = circle
          .animate()
          .fadeIn(duration: AppMotion.base, curve: AppMotion.arrive)
          .scaleXY(begin: 0.86, end: 1, duration: AppMotion.story, curve: AppMotion.knot);
      order = order
          .animate(delay: AppMotion.base)
          .scaleXY(begin: 0, end: 1, duration: AppMotion.move, curve: AppMotion.knot)
          .then(delay: AppMotion.pulse)
          .moveY(begin: 0, end: -dot * 0.5, duration: AppMotion.quick, curve: Curves.easeOut)
          .then()
          .moveY(begin: 0, end: dot * 0.5, duration: AppMotion.base, curve: Curves.bounceOut);
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        circle,
        Positioned(right: (size - disc) / 2 + disc * 0.06, top: (size - disc) / 2 + disc * 0.06, child: order),
      ],
    );
  }
}
