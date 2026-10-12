import 'dart:async';

import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/presentation/pages/product_editor_page.dart';
import 'package:apamuy/features/merchant_catalog/presentation/providers/menu_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lo que se cambia en plena atención (precio, disponible y cuántos quedan),
/// sin abrir el producto. «Más detalles» lleva a la edición completa.
Future<void> showQuickEditSheet(BuildContext context, {required String storeId, required String productId}) {
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _QuickEdit(storeId: storeId, productId: productId),
  );
}

class _QuickEdit extends ConsumerWidget {
  const _QuickEdit({required this.storeId, required this.productId});

  final String storeId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(storeMenuProvider(storeId))) {
      AsyncValue(:final value?) => switch (value.product(productId)) {
        final product? => _QuickEditForm(menu: value, product: product),
        null => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            kind: AppEmptyKind.noResults,
            title: 'Ya no está en la carta',
            message: 'Quizá lo quitaron desde la web.',
            compact: true,
          ),
        ),
      },
      AsyncValue(:final error?) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppEmptyState.fromError(error, compact: true),
      ),
      _ => const SizedBox(
        height: 240,
        child: Center(child: AppLoader(semanticsLabel: 'Cargando el producto')),
      ),
    };
  }
}

class _QuickEditForm extends ConsumerStatefulWidget {
  const _QuickEditForm({required this.menu, required this.product});

  final StoreMenu menu;
  final MenuProduct product;

  @override
  ConsumerState<_QuickEditForm> createState() => _QuickEditFormState();
}

class _QuickEditFormState extends ConsumerState<_QuickEditForm> with PartnerActionRunner {
  static const _step = Money(50);

  late Money _price = widget.product.price;
  late bool _available = widget.product.isAvailable;
  late int? _stock = widget.product.stock;

  MenuProduct get _product => widget.product;

  void _changePrice(Money delta) {
    final next = _price + delta;
    if (next.cents <= 0) return;
    HapticFeedback.selectionClick().ignore();
    setState(() => _price = next);
  }

  void _changeStock(int delta) {
    final next = (_stock ?? 0) + delta;
    if (next < 0) return;
    HapticFeedback.selectionClick().ignore();
    setState(() => _stock = next);
  }

  Future<void> _save() async {
    final draft = ProductDraft.fromProduct(_product).copyWith(
      price: _product.hasVariants ? null : _price,
      isAvailable: _available,
      stock: () => _stock,
    );
    final ok = await run(
      () => ref.read(menuActionsProvider.notifier).saveProduct(menu: widget.menu, draft: draft, productId: _product.id),
      success: 'Producto guardado.',
      retry: _save,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  void _details() {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    unawaited(
      router.pushNamed(
        ProductEditorPage.name,
        pathParameters: {'storeId': widget.menu.storeId, 'productId': _product.id},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final section = widget.menu.sections.where((s) => s.id == _product.sectionId).firstOrNull?.name;
    final changed = _price != _product.price || _available != _product.isAvailable || _stock != _product.stock;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppNetworkImage(url: _product.imageUrl, width: 56, height: 56, borderRadius: AppRadius.tile),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text(_product.name, style: theme.textTheme.titleMedium)),
                      if (section != null)
                        Text(section, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Precio', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            if (_product.hasVariants)
              Text(
                'Tiene variantes: el precio se cambia en cada una, desde la web.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              )
            else
              _Stepper(
                value: Formatters.money(_price),
                large: true,
                decreaseLabel: 'Bajar 50 céntimos',
                increaseLabel: 'Subir 50 céntimos',
                onDecrease: busy || _price.cents <= _step.cents ? null : () => _changePrice(Money(-_step.cents)),
                onIncrease: busy ? null : () => _changePrice(_step),
              ),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: context.apamuy.card,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.tile,
                side: BorderSide(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Disponible'),
                    value: _available,
                    onChanged: busy
                        ? null
                        : (value) {
                            HapticFeedback.selectionClick().ignore();
                            setState(() => _available = value);
                          },
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quedan', style: theme.textTheme.bodyLarge),
                        Text(
                          'Baja con cada pedido; en cero ya no se puede pedir.',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppChip(
                              label: 'Sin límite',
                              variant: AppChipVariant.choice,
                              selected: _stock == null,
                              onTap: busy ? null : () => setState(() => _stock = null),
                            ),
                            AppChip(
                              label: 'Contar',
                              variant: AppChipVariant.choice,
                              selected: _stock != null,
                              onTap: busy || _stock != null ? null : () => setState(() => _stock = 10),
                            ),
                            if (_stock case final stock?)
                              _Stepper(
                                value: '$stock',
                                decreaseLabel: 'Uno menos',
                                increaseLabel: 'Uno más',
                                onDecrease: busy || stock == 0 ? null : () => _changeStock(-1),
                                onIncrease: busy ? null : () => _changeStock(1),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                AppButton.secondary(label: 'Más detalles', expand: false, onPressed: busy ? null : _details),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Guardar',
                    loading: busy,
                    onPressed: busy || !changed ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// − valor +, con botones de 48 px.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onDecrease,
    required this.onIncrease,
    this.large = false,
  });

  final String value;
  final String decreaseLabel;
  final String increaseLabel;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = IconButton.styleFrom(
      backgroundColor: context.apamuy.raised,
      fixedSize: const Size.square(AppSpacing.minTouch),
    );
    final display = Text(
      value,
      textAlign: TextAlign.center,
      style: AppTypography.price(context, size: large ? 26 : 18),
    );
    return Row(
      mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
      children: [
        IconButton(tooltip: decreaseLabel, style: style, onPressed: onDecrease, icon: const Icon(Icons.remove_rounded)),
        if (large)
          Expanded(
            child: Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.tile,
                border: Border.all(color: scheme.primary, width: 2),
              ),
              child: Semantics(liveRegion: true, child: display),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Semantics(liveRegion: true, child: display),
          ),
        IconButton(tooltip: increaseLabel, style: style, onPressed: onIncrease, icon: const Icon(Icons.add_rounded)),
      ],
    );
  }
}
