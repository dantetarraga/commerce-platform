import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/shared/design_system/components/app_network_image.dart';
import 'package:chaski/shared/design_system/components/app_price.dart';
import 'package:chaski/shared/design_system/components/app_skeleton.dart';
import 'package:chaski/shared/design_system/components/app_toast.dart';
import 'package:chaski/shared/design_system/components/fly_to_purchase_bar.dart';
import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/app_typography.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class ProductCardData {
  const ProductCardData({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.fromPrice = false,
    this.subtitle,
    this.promo,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final Money price;
  final bool isAvailable;

  /// Tiene variantes: el precio es "Desde".
  final bool fromPrice;

  /// Contexto opcional (nombre del negocio en búsquedas, "Hecho en Espinar").
  final String? subtitle;
  final String? promo;
}

enum AppProductCardVariant {
  /// Fila del menú: texto a la izquierda, foto cuadrada con "+" a la derecha.
  row,

  /// Mosaico cuadrado (colecciones, "Hecho en Espinar").
  tile,

  /// Foto grande ("Lo más pedido").
  featured,
}

/// Producto. Si [onQuickAdd] no es nulo aparece el "+" rápido, que agrega sin
/// abrir el detalle (solo para productos sin opciones obligatorias).
class AppProductCard extends StatelessWidget {
  const AppProductCard({
    required this.data,
    required this.onTap,
    this.variant = AppProductCardVariant.row,
    this.onQuickAdd,
    this.width,
    this.heroTag,
    super.key,
  });

  final ProductCardData data;
  final VoidCallback? onTap;
  final AppProductCardVariant variant;
  final Future<bool> Function()? onQuickAdd;
  final double? width;
  final Object? heroTag;

  String get _semantics => [
    data.name,
    if (data.fromPrice) 'desde ${spokenMoney(data.price)}' else spokenMoney(data.price),
    if (!data.isAvailable) 'Agotado',
    if (data.subtitle != null) data.subtitle!,
  ].join('. ');

  @override
  Widget build(BuildContext context) {
    final enabled = data.isAvailable && onTap != null;
    final body = switch (variant) {
      AppProductCardVariant.row => _RowBody(card: this),
      AppProductCardVariant.tile || AppProductCardVariant.featured => _TileBody(card: this),
    };
    return Semantics(
      button: enabled,
      label: _semantics,
      child: Opacity(
        opacity: data.isAvailable ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: variant == AppProductCardVariant.row ? null : AppRadius.card,
            child: body,
          ),
        ),
      ),
    );
  }
}

class _Image extends StatefulWidget {
  const _Image({required this.card, required this.width, required this.height});

  final AppProductCard card;
  final double width;
  final double height;

  @override
  State<_Image> createState() => _ImageState();
}

class _ImageState extends State<_Image> {
  final GlobalKey _imageKey = GlobalKey();
  bool _adding = false;

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);
    final from = globalRectOf(_imageKey);
    try {
      final added = await widget.card.onQuickAdd!();
      if (added && mounted && from != null) await flyToPurchaseBar(context, from: from, imageUrl: widget.card.data.imageUrl);
    } on Exception {
      if (mounted) AppToast.show(context, 'No pudimos agregar el producto. Inténtalo otra vez.', kind: AppToastKind.error);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = AppNetworkImage(
      key: _imageKey,
      url: widget.card.data.imageUrl,
      width: widget.width,
      height: widget.height,
      borderRadius: AppRadius.card,
      fallbackIcon: Icons.fastfood_rounded,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (widget.card.heroTag == null) image else Hero(tag: widget.card.heroTag!, child: image),
        if (widget.card.onQuickAdd != null && widget.card.data.isAvailable)
          Positioned(
            right: -6,
            bottom: -6,
            child: QuickAddButton(onPressed: _add, loading: _adding),
          ),
      ],
    );
  }
}

class _RowBody extends StatelessWidget {
  const _RowBody({required this.card});

  final AppProductCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = card.data;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? context.chaski.raised : const Color(0xFFEBE7DC),
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name, style: theme.textTheme.titleSmall),
                  if (data.description != null) ...[
                    const SizedBox(height: 2),
                    Text(data.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppPrice(
                        data.price,
                        variant: data.fromPrice ? AppPriceVariant.from : AppPriceVariant.regular,
                        size: 18,
                      ),
                      if (!data.isAvailable) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text('Agotado por hoy', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Image(card: card, width: 104, height: 116),
        ],
      ),
    );
  }
}

class _TileBody extends StatelessWidget {
  const _TileBody({required this.card});

  final AppProductCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = card.data;
    final featured = card.variant == AppProductCardVariant.featured;
    final w = card.width ?? (featured ? 200.0 : 150.0);
    return SizedBox(
      width: w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Image(card: card, width: w, height: featured ? w * 0.75 : w),
          const SizedBox(height: AppSpacing.xs),
          Text(data.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (data.subtitle != null) Text(data.subtitle!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            '${data.fromPrice ? 'Desde ' : ''}${Formatters.money(data.price)}',
            style: AppTypography.price(context, size: 15),
          ),
        ],
      ),
    );
  }
}

/// Botón "+" que agrega directo. Responde con un pulso y vibración leve.
class QuickAddButton extends StatefulWidget {
  const QuickAddButton({required this.onPressed, this.loading = false, super.key});

  final bool loading;

  final VoidCallback onPressed;

  @override
  State<QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<QuickAddButton> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.lightImpact().ignore();
    if (!reduceMotionOf(context)) _pulse.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Agregar a la bolsa',
      onTap: widget.loading ? null : _tap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.loading ? null : _tap,
          excludeFromSemantics: true,
          child: SizedBox.square(
            dimension: AppSpacing.minTouch,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final t = _pulse.value;
                  final scale = 1 + 0.18 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Material(
                  color: scheme.primary,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 3,
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: 34,
                    child: Icon(
                      widget.loading ? Icons.more_horiz_rounded : Icons.add_rounded,
                      color: scheme.onPrimary,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton de fila de producto: la misma tarjeta con datos de relleno, así
/// la geometría es siempre la de [AppProductCardVariant.row].
class AppProductRowSkeleton extends StatelessWidget {
  const AppProductRowSkeleton({super.key});

  static const _placeholder = ProductCardData(
    id: 'skeleton',
    name: 'Caldo de gallina',
    description: 'Presa, papa amarilla y fideos, con hierbabuena',
    price: Money(1800),
  );

  @override
  Widget build(BuildContext context) =>
      const AppSkeletonizer(child: AppProductCard(data: _placeholder, onTap: null));
}
