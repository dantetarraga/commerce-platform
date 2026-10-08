import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';

enum AppPriceVariant {
  regular,

  /// Precio con descuento: el anterior tachado al lado.
  discount,

  /// "Desde S/ 12.00" (productos con variantes).
  from,

  /// Monto cero mostrado como "Gratis" (envío).
  free,
}

/// Precio en cifras tabulares (las columnas se alinean) con Outfit.
/// Se lee con lectores de pantalla como "catorce soles".
class AppPrice extends StatelessWidget {
  const AppPrice(
    this.money, {
    this.variant = AppPriceVariant.regular,
    this.previous,
    this.size = 16,
    this.color,
    super.key,
  });

  final Money money;
  final AppPriceVariant variant;

  /// Precio anterior, solo para [AppPriceVariant.discount].
  final Money? previous;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = AppTypography.price(context, size: size).copyWith(color: color);
    final isFree = variant == AppPriceVariant.free && money.isZero;
    final text = isFree ? 'Gratis' : '${variant == AppPriceVariant.from ? 'Desde ' : ''}${Formatters.money(money)}';

    return Semantics(
      label: isFree ? 'Gratis' : spokenMoney(money, from: variant == AppPriceVariant.from),
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 2,
        children: [
          Text(text, style: isFree ? style.copyWith(color: context.apamuy.success) : style),
          if (variant == AppPriceVariant.discount && previous != null) ...[
            const SizedBox(width: 6),
            Text(
              Formatters.money(previous!),
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.lineThrough,
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "S/ 14.50" → "14 soles con 50 céntimos" para lectores de pantalla.
String spokenMoney(Money money, {bool from = false}) {
  final soles = money.cents ~/ 100;
  final cents = money.cents % 100;
  final base = cents == 0 ? '$soles soles' : '$soles soles con $cents céntimos';
  return from ? 'desde $base' : base;
}
