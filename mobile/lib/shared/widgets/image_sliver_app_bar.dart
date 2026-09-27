import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// App bar con foto de portada. El título aparece solo al colapsar; los
/// botones van en círculos blancos para leerse sobre cualquier foto.
///
/// Abajo, la hoja blanca (radio 24) sube sobre la foto; [edge] se monta sobre
/// ese borde (p. ej. el logo del negocio). Ambos se desvanecen al colapsar.
///
/// La portada hace parallax al hacer scroll y se agranda al estirar (iOS).
/// Con [ImageSliverAppBar.loading] dibuja la misma geometría: si ya se conoce
/// la portada (viene de la card) la muestra al instante; si no, shimmer.
/// Con [heroTag], la foto vuela desde la card de origen.
class ImageSliverAppBar extends StatelessWidget {
  const ImageSliverAppBar({
    required this.title,
    required this.imageUrl,
    this.expandedHeight = defaultExpandedHeight,
    this.fallbackIcon = Icons.restaurant_rounded,
    this.heroTag,
    this.leadingIcon = Icons.arrow_back_rounded,
    this.actions = const [],
    this.trailing,
    this.edge,
    this.edgeHeight = 0,
    this.dimmed = false,
    super.key,
  }) : loading = false;

  const ImageSliverAppBar.loading({
    this.expandedHeight = defaultExpandedHeight,
    this.imageUrl,
    this.heroTag,
    this.leadingIcon = Icons.arrow_back_rounded,
    this.edge,
    this.edgeHeight = 0,
    super.key,
  }) : title = '',
       fallbackIcon = Icons.restaurant_rounded,
       actions = const [],
       trailing = null,
       dimmed = false,
       loading = true;

  static const defaultExpandedHeight = 260.0;

  /// Alto de la hoja que sube sobre la foto.
  static const sheetLip = 24.0;

  final String title;
  final String? imageUrl;
  final double expandedHeight;
  final IconData fallbackIcon;
  final Object? heroTag;
  final bool loading;

  /// Atrás (flecha) o cerrar (×) en pantallas tipo modal.
  final IconData leadingIcon;

  /// Botones redondos a la derecha (buscar…).
  final List<PhotoAction> actions;

  /// Último botón, ya con su propio círculo (p. ej. `FavoriteButton(onPhoto: true)`).
  final Widget? trailing;

  /// Pieza montada sobre el borde de la hoja, alineada al margen izquierdo.
  final Widget? edge;

  /// Alto total de [edge]; su parte baja ([sheetLip]) queda sobre la hoja.
  final double edgeHeight;

  /// Foto desaturada (negocio cerrado).
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    Widget background = loading && imageUrl == null
        ? const Skeleton(
            child: SkeletonBox(height: double.infinity, borderRadius: BorderRadius.zero),
          )
        : AppNetworkImage(url: imageUrl, fallbackIcon: fallbackIcon);
    if (dimmed) background = ColorFiltered(colorFilter: _desaturate, child: background);
    if (heroTag != null) background = Hero(tag: heroTag!, child: background);
    final surface = Theme.of(context).colorScheme.surface;
    final reduce = reduceMotionOf(context);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final collapsed = constraints.scrollOffset > expandedHeight - kToolbarHeight - sheetLip;
        return SliverAppBar(
          pinned: true,
          stretch: true,
          expandedHeight: expandedHeight,
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Center(
              child: PhotoCircleButton(
                action: PhotoAction(
                  icon: leadingIcon,
                  tooltip: leadingIcon == Icons.close_rounded
                      ? MaterialLocalizations.of(context).closeButtonTooltip
                      : MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                ),
                onPhoto: !collapsed,
              ),
            ),
          ),
          title: AnimatedOpacity(
            opacity: collapsed ? 1 : 0,
            duration: reduce ? Duration.zero : AppMotion.quick,
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          actions: [
            for (final action in actions) PhotoCircleButton(action: action, onPhoto: !collapsed),
            ?trailing,
            const SizedBox(width: AppSpacing.xs),
          ],
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              // Por defecto: parallax al colapsar y zoom al estirar.
              FlexibleSpaceBar(background: background),
              // La hoja y el logo también mientras carga: así no salta al llegar.
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: collapsed ? 0 : 1,
                    duration: reduce ? Duration.zero : AppMotion.quick,
                    child: SizedBox(
                      height: (edge == null ? sheetLip : edgeHeight) + 1,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: sheetLip + 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: surface, borderRadius: AppRadius.sheet),
                            ),
                          ),
                          if (edge != null) Positioned(left: AppSpacing.gutter, bottom: 1, child: edge!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Matriz de gris al 70 %: el negocio cerrado se ve "apagado".
const _desaturate = ColorFilter.matrix([
  0.5, 0.45, 0.05, 0, 0, //
  0.2, 0.75, 0.05, 0, 0, //
  0.2, 0.45, 0.35, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Acción de un botón redondo sobre foto.
@immutable
class PhotoAction {
  const PhotoAction({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

/// Botón circular blanco sobre la foto; sin círculo cuando la barra colapsa.
class PhotoCircleButton extends StatelessWidget {
  const PhotoCircleButton({required this.action, this.onPhoto = true, super.key});

  final PhotoAction action;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chaski = context.chaski;
    return IconButton(
      tooltip: action.tooltip,
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 22),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        // Área táctil de 48 aunque el círculo mida 40.
        tapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: onPhoto ? chaski.onPhoto.withValues(alpha: 0.94) : Colors.transparent,
        foregroundColor: onPhoto ? AppColors.tinta : scheme.onSurface,
      ),
    );
  }
}
