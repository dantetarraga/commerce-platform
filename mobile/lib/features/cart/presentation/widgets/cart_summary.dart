import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/cart/domain/entities/cart.dart';
import 'package:apamuy/features/cart/presentation/widgets/coupon_row.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pie de la bolsa: nota para el negocio, franja del mínimo, cupón y subtotal.
class CartSummary extends StatelessWidget {
  const CartSummary({required this.cart, required this.onEditNote, super.key});

  final Cart cart;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final coupon = cart.coupon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StoreNoteRow(note: cart.note, onTap: onEditNote),
        const SizedBox(height: AppSpacing.md),
        AnimatedSize(
          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
          curve: AppMotion.arrive,
          child: cart.reachesMinimum
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MinimumStrip(cart: cart),
                ),
        ),
        const CouponRow(),
        const SizedBox(height: AppSpacing.xs),
        AmountRow(
          label: 'Subtotal',
          amount: cart.subtotal,
          style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (coupon != null && !cart.discount.isZero)
          AmountRow.discount(
            label: 'Cupón ${coupon.code}',
            amount: cart.discount,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.apamuy.success, fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'El envío y la propina los ves en tu boleta.',
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// "+ Nota para el negocio (opcional)" o la nota ya escrita.
class StoreNoteRow extends StatelessWidget {
  const StoreNoteRow({required this.note, required this.onTap, super.key});

  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final empty = note.isEmpty;
    return AppTapSurface(
      semanticLabel: empty ? 'Agregar nota para el negocio, opcional' : 'Nota para el negocio: $note. Editar',
      color: context.apamuy.raised,
      borderRadius: AppRadius.tile,
      pressScale: 1,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(empty ? Icons.add_rounded : Icons.sticky_note_2_outlined, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: empty
                    ? Text.rich(
                        TextSpan(
                          text: 'Nota para el negocio',
                          children: [
                            TextSpan(
                              text: ' (opcional)',
                              style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        style: theme.textTheme.labelLarge,
                      )
                    : Text('“$note”', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              ),
              if (!empty) Icon(Icons.edit_outlined, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Franja hacia el pedido mínimo: un objetivo claro en vez de un error al final.
class MinimumStrip extends StatelessWidget {
  const MinimumStrip({required this.cart, super.key});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final apamuy = context.apamuy;
    return Semantics(
      label: 'Te faltan ${spokenMoney(cart.missingForMinimum)} para el pedido mínimo',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        decoration: BoxDecoration(color: apamuy.accentSoft, borderRadius: AppRadius.tile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: apamuy.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: apamuy.onAccent, width: 1.5),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Te faltan ',
                      children: [
                        TextSpan(
                          text: Formatters.money(cart.missingForMinimum),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: AppTypography.tabularFigures),
                        ),
                        const TextSpan(text: ' para el pedido mínimo'),
                      ],
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: const BorderRadius.all(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: cart.minimumProgress),
                duration: reduceMotionOf(context) ? Duration.zero : AppMotion.move,
                curve: AppMotion.arrive,
                builder: (context, p, _) => LinearProgressIndicator(
                  value: p,
                  minHeight: 5,
                  color: apamuy.accent,
                  backgroundColor: apamuy.accent.withValues(alpha: 0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
