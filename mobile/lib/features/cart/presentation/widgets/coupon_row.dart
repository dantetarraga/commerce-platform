import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/features/cart/presentation/providers/cart_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "¿Tienes un cupón?": se abre en un campo y, aplicado, queda como cinta.
class CouponRow extends ConsumerStatefulWidget {
  const CouponRow({super.key});

  @override
  ConsumerState<CouponRow> createState() => _CouponRowState();
}

class _CouponRowState extends ConsumerState<CouponRow> {
  final _code = TextEditingController();
  var _open = false;
  var _loading = false;
  Failure? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await ref.read(cartControllerProvider.notifier).applyCoupon(_code.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      if (error == null) _open = false;
    });
    if (error == null) {
      HapticFeedback.lightImpact().ignore();
      AppToast.show(context, 'Cupón aplicado', kind: AppToastKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coupon = ref.watch(cartControllerProvider.select((c) => c.value?.coupon));
    final apamuy = context.apamuy;

    if (coupon != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Container(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          decoration: BoxDecoration(color: apamuy.accent, borderRadius: AppRadius.tile),
          child: Row(
            children: [
              Icon(Icons.local_offer_rounded, color: apamuy.onAccent, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text('${coupon.code} · ${coupon.label}', style: theme.textTheme.labelLarge?.copyWith(color: apamuy.onAccent)),
              ),
              IconButton(
                tooltip: 'Quitar cupón',
                color: apamuy.onAccent,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => ref.read(cartControllerProvider.notifier).removeCoupon(),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
      curve: AppMotion.arrive,
      alignment: Alignment.topCenter,
      child: !_open
          ? Align(
              alignment: Alignment.centerLeft,
              child: AppButton.ghost(label: '¿Tienes un cupón?', icon: Icons.local_offer_outlined, onPressed: () => setState(() => _open = true)),
            )
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'Cupón',
                      controller: _code,
                      autofocus: true,
                      hint: 'BIENVENIDA',
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _apply(),
                      errorText: _error?.message,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Padding(
                    padding: EdgeInsets.only(bottom: _error == null ? 4 : 26),
                    child: AppButton.secondary(label: 'Aplicar', expand: false, size: AppButtonSize.md, loading: _loading, onPressed: _apply),
                  ),
                ],
              ),
            ),
    );
  }
}
