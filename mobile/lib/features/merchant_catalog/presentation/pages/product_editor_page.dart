import 'dart:async';

import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/presentation/providers/menu_providers.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/menu_page_scaffold.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/product_photo_field.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/section_name_dialog.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Crear un producto ([productId] nulo) o editar uno de la carta. Con [onDone]
/// va dentro del panel lateral de la tablet: sin volver y sin salir al guardar.
class ProductEditorPage extends ConsumerWidget {
  const ProductEditorPage({required this.storeId, this.productId, this.onDone, super.key});

  static const name = 'productEditor';
  static const newName = 'productNew';

  final String storeId;
  final String? productId;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(storeMenuProvider(storeId));
    final title = productId == null ? 'Nuevo ' : 'Editar ';
    final embedded = onDone != null;
    return switch (menu) {
      AsyncValue(:final value?) => switch (productId) {
        null => _ProductForm(menu: value, onDone: onDone),
        final id => switch (value.product(id)) {
          final product? => _ProductForm(menu: value, product: product, onDone: onDone),
          null => MenuPageScaffold(
            title: title,
            accent: 'producto.',
            showBack: !embedded,
            body: const AppEmptyState(
              kind: AppEmptyKind.noResults,
              title: 'Ya no está en la carta',
              message: 'Quizá lo quitaron desde la web.',
            ),
          ),
        },
      },
      AsyncValue(:final error?) => MenuPageScaffold(
        title: title,
        accent: 'producto.',
        showBack: !embedded,
        body: AppEmptyState.fromError(error, onRetry: () => ref.invalidate(storeMenuProvider(storeId))),
      ),
      _ => MenuPageScaffold(
        title: title,
        accent: 'producto.',
        showBack: !embedded,
        body: const Center(child: AppLoader(semanticsLabel: 'Cargando la carta')),
      ),
    };
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({required this.menu, this.product, this.onDone});

  final StoreMenu menu;
  final MenuProduct? product;
  final VoidCallback? onDone;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> with PartnerActionRunner {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(
    text: widget.product == null ? '' : (widget.product!.price.cents / 100).toStringAsFixed(2),
  );
  late final _description = TextEditingController(text: widget.product?.description);
  late final _stock = TextEditingController(text: widget.product?.stock?.toString());
  late String? _sectionId = widget.product?.sectionId;
  late bool _available = widget.product?.isAvailable ?? true;
  late PhotoChoice _photo = KeepPhoto(widget.product?.imageUrl);
  late bool _showDescription = (widget.product?.description ?? '').isNotEmpty;

  /// Lo que había al abrir, para saber si hay algo sin guardar.
  late final String _initial;

  /// De 0 a 1 mientras sube la foto.
  double? _upload;

  /// Ya guardó o confirmó descartar: puede salir sin preguntar.
  var _leaving = false;

  /// Secciones creadas aquí mismo, antes de que la carta se vuelva a pedir.
  final _addedSections = <MenuSection>[];

  bool get _hasVariants => widget.product?.hasVariants ?? false;
  bool get _embedded => widget.onDone != null;

  String _snapshot() => [
    _name.text.trim(),
    _price.text.trim(),
    _description.text.trim(),
    _stock.text.trim(),
    _sectionId,
    _available,
    switch (_photo) {
      KeepPhoto(:final url) => url,
      NewPhoto(:final photo) => photo.path,
      NoPhoto() => '',
    },
  ].join('|');

  @override
  void initState() {
    super.initState();
    _initial = _snapshot();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _finish() {
    setState(() => _leaving = true);
    if (widget.onDone case final done?) {
      done();
    } else {
      context.pop();
    }
  }

  Future<void> _confirmLeave() async {
    if (_snapshot() == _initial) {
      _finish();
      return;
    }
    final discard = await showAppConfirmDialog(
      context,
      title: '¿Descartar los cambios?',
      message: 'Lo que cambiaste en este producto no se guardará.',
      confirmLabel: 'Descartar',
      cancelLabel: 'Seguir editando',
      destructive: true,
    );
    if (discard && mounted) _finish();
  }

  Future<void> _newSection() async {
    final name = await showSectionNameDialog(context, title: 'Nueva sección');
    if (name == null || !mounted) return;
    final result = await ref.read(menuActionsProvider.notifier).createSection(widget.menu.storeId, name);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _addedSections.add(value);
          _sectionId = value.id;
        });
      case Err(:final failure):
        AppToast.show(context, failure.message, kind: AppToastKind.error);
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final stock = _stock.text.trim();
    final draft = ProductDraft(
      name: _name.text.trim(),
      description: _description.text.trim(),
      price: _hasVariants ? null : Money.tryParse(_price.text, currency: widget.menu.currency),
      imageUrl: switch (_photo) {
        KeepPhoto(:final url) => url,
        _ => null,
      },
      sectionId: _sectionId,
      stock: stock.isEmpty ? null : int.parse(stock),
      isAvailable: _available,
    );
    final photo = switch (_photo) {
      NewPhoto(:final photo) => photo,
      _ => null,
    };
    final ok = await run(
      () => ref
          .read(menuActionsProvider.notifier)
          .saveProduct(
            menu: widget.menu,
            draft: draft,
            productId: widget.product?.id,
            photo: photo,
            onProgress: photo == null
                ? null
                : (progress) {
                    if (mounted) setState(() => _upload = progress);
                  },
          ),
      success: widget.product == null ? 'Producto agregado a la carta.' : 'Producto guardado.',
      retry: _save,
    );
    if (mounted) setState(() => _upload = null);
    if (ok && mounted) _finish();
  }

  Future<void> _remove() async {
    final product = widget.product!;
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Quitar producto',
      message: '«${product.name}» saldrá de la carta. Los pedidos anteriores no cambian.',
      confirmLabel: 'Quitar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final ok = await run(
      () => ref.read(menuActionsProvider.notifier).removeProduct(product.id),
      success: 'Producto quitado.',
    );
    if (ok && mounted) _finish();
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Escribe el nombre del producto.';
    if (text.length > 80) return 'Máximo 80 caracteres.';
    return null;
  }

  String? _validatePrice(String? value) {
    if (_hasVariants) return null;
    final price = Money.tryParse(value ?? '');
    if (price == null || price.isZero) return 'Escribe un precio, por ejemplo 12.50.';
    if (!RegExp(r'^\s*(S/)?\s*\d+([.,]\d{1,2})?\s*$').hasMatch(value!)) return 'Usa hasta 2 decimales.';
    return null;
  }

  String? _validateStock(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return int.tryParse(text) == null ? 'Usa un número entero.' : null;
  }

  String get _saveLabel {
    if (_upload case final progress?) return 'Subiendo foto ${(progress * 100).round()} %';
    return widget.product != null ? 'Guardar cambios' : 'Agregar a la carta';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = [...widget.menu.sections, ..._addedSections];
    final editing = widget.product != null;
    final scaffold = MenuPageScaffold(
      title: editing ? 'Editar ' : 'Nuevo ',
      accent: 'producto.',
      showBack: !_embedded,
      trailing: [
        if (editing)
          IconButton(
            tooltip: 'Quitar producto',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: busy ? null : _remove,
          ),
        if (_embedded)
          IconButton(tooltip: 'Cerrar', icon: const Icon(Icons.close_rounded), onPressed: busy ? null : _confirmLeave),
      ],
      bottom: AppButton(
        label: _saveLabel,
        loading: busy && _upload == null,
        onPressed: busy ? null : _save,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
          children: [
            ProductPhotoField(value: _photo, enabled: !busy, onChanged: (choice) => setState(() => _photo = choice)),
            if (_upload case final progress?) ...[
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(value: progress, semanticsLabel: 'Subiendo la foto'),
            ],
            const SizedBox(height: AppSpacing.md),
            _AvailableCard(value: _available, onChanged: busy ? null : (value) => setState(() => _available = value)),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: 'Nombre',
              controller: _name,
              enabled: !busy,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: _validateName,
            ),
            const SizedBox(height: AppSpacing.md),
            _SideBySide(
              first: AppInput(
                label: 'Precio (S/)',
                controller: _price,
                enabled: !busy && !_hasVariants,
                hint: '12.50',
                helper: _hasVariants ? 'Tiene variantes: se cobra el precio de cada una (se editan en la web).' : null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: _validatePrice,
              ),
              second: AppInput(
                label: 'Stock',
                controller: _stock,
                enabled: !busy,
                hint: 'Sin límite',
                keyboardType: TextInputType.number,
                validator: _validateStock,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Sección', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final (id, label) in [(null, 'Sin sección'), for (final s in sections) (s.id, s.name)])
                  AppChip(
                    label: label,
                    variant: AppChipVariant.choice,
                    selected: _sectionId == id || (id == null && !sections.any((s) => s.id == _sectionId)),
                    onTap: busy ? null : () => setState(() => _sectionId = id),
                  ),
                AppChip(
                  label: 'Nueva',
                  icon: Icons.add_rounded,
                  variant: AppChipVariant.suggestion,
                  onTap: busy ? null : _newSection,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_showDescription)
              AppInput(
                label: 'Descripción (opcional)',
                controller: _description,
                enabled: !busy,
                variant: AppInputVariant.note,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: busy ? null : () => setState(() => _showDescription = true),
                  icon: const Icon(Icons.notes_rounded),
                  label: const Text('Agregar descripción'),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            _CustomerPreview(
              name: _name,
              price: _price,
              description: _description,
              photo: _photo,
              available: _available,
              fromPrice: _hasVariants,
              fallbackPrice: widget.product?.price,
              currency: widget.menu.currency,
            ),
          ],
        ),
      ),
    );
    if (_embedded) return scaffold;
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) unawaited(_confirmLeave());
      },
      child: scaffold,
    );
  }
}

/// Lo primero que se cambia en plena atención: si se puede pedir hoy.
class _AvailableCard extends StatelessWidget {
  const _AvailableCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = value ? scheme.onSecondaryContainer : scheme.onSurface;
    return Material(
      color: value ? scheme.secondaryContainer : context.apamuy.raised,
      borderRadius: AppRadius.tile,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          'Disponible para pedir',
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          value ? 'Apágalo si se te acabó hoy.' : 'Los clientes lo ven agotado.',
          style: TextStyle(color: fg),
        ),
      ),
    );
  }
}

/// Dos campos en una fila; con poco ancho o letra grande, uno debajo del otro.
class _SideBySide extends StatelessWidget {
  const _SideBySide({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy = constraints.maxWidth >= 320 && MediaQuery.textScalerOf(context).scale(1) <= 1.15;
        if (!roomy) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppSpacing.md),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: first),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: 5, child: second),
          ],
        );
      },
    );
  }
}

/// La fila del menú tal como la verá el cliente, al día con lo que se escribe.
class _CustomerPreview extends StatelessWidget {
  const _CustomerPreview({
    required this.name,
    required this.price,
    required this.description,
    required this.photo,
    required this.available,
    required this.fromPrice,
    required this.fallbackPrice,
    required this.currency,
  });

  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController description;
  final PhotoChoice photo;
  final bool available;
  final bool fromPrice;
  final Money? fallbackPrice;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Así lo ve el cliente', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        ListenableBuilder(
          listenable: Listenable.merge([name, price, description]),
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.tile,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: ExcludeSemantics(
                child: AppProductCard(
                  onTap: () {},
                  data: ProductCardData(
                    id: 'preview',
                    name: name.text.trim().isEmpty ? 'Nombre del producto' : name.text.trim(),
                    description: description.text.trim().isEmpty ? null : description.text.trim(),
                    imageUrl: switch (photo) {
                      KeepPhoto(:final url) => url,
                      NewPhoto(:final photo) => photo.path,
                      NoPhoto() => null,
                    },
                    price:
                        (fromPrice ? null : Money.tryParse(price.text, currency: currency)) ??
                        fallbackPrice ??
                        Money(0, currency: currency),
                    isAvailable: available,
                    fromPrice: fromPrice,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
