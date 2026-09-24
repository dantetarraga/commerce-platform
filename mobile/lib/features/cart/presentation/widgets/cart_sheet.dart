import 'package:chaski/core/domain/quantity.dart';
import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/cart/domain/entities/cart.dart';
import 'package:chaski/features/cart/presentation/providers/cart_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre "Tu bolsa" como hoja: nunca saca al usuario de lo que estaba viendo.
///
/// [onCheckout] y [onExplore] los provee la app (el feature no conoce rutas).
Future<void> showCartSheet(BuildContext context, {required VoidCallback onCheckout, required VoidCallback onExplore}) {
  return showAppBottomSheet<void>(
    context,
    size: AppSheetSize.full,
    builder: (_) => CartSheet(onCheckout: onCheckout, onExplore: onExplore),
  );
}

/// Pregunta antes de reemplazar una bolsa de otro negocio. `true` = vaciar.
Future<bool> confirmReplaceCart(BuildContext context, {required CartStore current, required CartStore incoming}) =>
    showAppConfirmDialog(
      context,
      title: '¿Empezamos otra bolsa?',
      message: 'Tu bolsa tiene productos de ${current.name}. Para pedir en ${incoming.name} la vaciamos primero.',
      confirmLabel: 'Vaciar y agregar',
      cancelLabel: 'Mantener mi bolsa',
    );

/// Hoja de texto corto (nota del negocio o de un producto). Devuelve el texto
/// o null si se cierra sin guardar.
Future<String?> _editNote(BuildContext context, {required String title, required String label, required String initial, required String hint}) async {
  final controller = TextEditingController(text: initial);
  final notes = await showAppBottomSheet<String>(
    context,
    title: title,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            label: label,
            controller: controller,
            variant: AppInputVariant.note,
            maxLength: 140,
            autofocus: true,
            hint: hint,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Guardar nota', onPressed: () => Navigator.of(sheetContext).pop(controller.text)),
        ],
      ),
    ),
  );
  controller.dispose();
  return notes?.trim();
}

class CartSheet extends ConsumerStatefulWidget {
  const CartSheet({required this.onCheckout, required this.onExplore, super.key});

  final VoidCallback onCheckout;
  final VoidCallback onExplore;

  @override
  ConsumerState<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<CartSheet> {
  final _listKey = GlobalKey<SliverAnimatedListState>();

  /// Copia local de las líneas que muestra la lista animada.
  late List<CartLine> _items = List.of(ref.read(cartControllerProvider).value?.lines ?? const []);

  /// Líneas quitadas deslizando: el Dismissible ya animó su salida.
  final _dismissed = <String>{};

  Duration get _duration => reduceMotionOf(context) ? Duration.zero : AppMotion.base;

  /// Sincroniza la lista animada con la bolsa: anima solo lo que entra o sale.
  void _sync(List<CartLine> next) {
    final list = _listKey.currentState;
    if (list == null) {
      _items = List.of(next);
      return;
    }
    final nextIds = {for (final l in next) l.id};
    for (var i = _items.length - 1; i >= 0; i--) {
      final old = _items[i];
      if (nextIds.contains(old.id)) continue;
      _items.removeAt(i);
      final silent = _dismissed.remove(old.id);
      list.removeItem(
        i,
        (context, animation) => silent ? const SizedBox.shrink() : _Appear(animation: animation, child: IgnorePointer(child: _CartLineTile(line: old))),
        duration: silent ? Duration.zero : _duration,
      );
    }
    final currentIds = {for (final l in _items) l.id};
    for (final (i, line) in next.indexed) {
      if (currentIds.contains(line.id)) continue;
      final at = i.clamp(0, _items.length);
      _items.insert(at, line);
      list.insertItem(at, duration: _duration);
    }
    // Mismo orden y conjunto: toma los datos nuevos (cantidades, notas).
    _items = List.of(next);
  }

  Future<void> _clear(Cart cart) async {
    final ok = await showAppConfirmDialog(
      context,
      title: '¿Vaciar tu bolsa?',
      message: 'Se quitarán todos los productos de ${cart.store?.name ?? 'la bolsa'}.',
      confirmLabel: 'Vaciar bolsa',
      destructive: true,
    );
    if (ok) await ref.read(cartControllerProvider.notifier).clear();
  }

  Future<void> _storeNote(Cart cart) async {
    final note = await _editNote(
      context,
      title: 'Nota para el negocio',
      label: cart.store?.name ?? 'Nota',
      initial: cart.note,
      hint: 'Ej.: sin ají en nada, tocar el timbre',
    );
    if (note != null) await ref.read(cartControllerProvider.notifier).setNote(note);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cartControllerProvider, (_, next) {
      final lines = next.value?.lines;
      if (lines != null) setState(() => _sync(lines));
    });
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cart = ref.watch(cartControllerProvider).value ?? Cart.empty;
    final store = cart.store;

    if (cart.isEmpty) {
      return AppEmptyState(
        title: 'Tu bolsa está vacía',
        message: 'Lo que agregues aparece aquí. Hay negocios abiertos cerca de ti ahora mismo.',
        actionLabel: 'Ver qué hay cerca',
        onAction: () {
          Navigator.of(context).pop();
          widget.onExplore();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.xs, AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text('Tu bolsa', style: theme.textTheme.headlineSmall)),
                    if (store != null)
                      Text(
                        '${store.name} · ${Formatters.eta(store.etaMinutes)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              AppButton.ghost(label: 'Vaciar', size: AppButtonSize.sm, onPressed: () => _clear(cart)),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAnimatedList(
                key: _listKey,
                initialItemCount: _items.length,
                itemBuilder: (context, index, animation) {
                  final line = _items[index];
                  return _Appear(
                    key: ValueKey(line.id),
                    animation: animation,
                    child: _CartLineTile(
                      line: line,
                      onDismissed: () => _dismissed.add(line.id),
                    ),
                  );
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
                sliver: SliverList.list(
                  children: [
                    _StoreNoteRow(note: cart.note, onTap: () => _storeNote(cart)),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedSize(
                      duration: _duration,
                      curve: AppMotion.postaOut,
                      child: cart.reachesMinimum
                          ? const SizedBox(width: double.infinity)
                          : Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _MinimumStrip(cart: cart)),
                    ),
                    const _CouponRow(),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(child: Text('Subtotal', style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant))),
                        AppPrice(cart.subtotal, size: 18),
                      ],
                    ),
                    if (!cart.discount.isZero)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Cupón ${cart.coupon!.code}', style: theme.textTheme.bodyMedium?.copyWith(color: context.chaski.success)),
                            ),
                            Text(
                              '− ${Formatters.money(cart.discount)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.chaski.success,
                                fontFeatures: AppTypography.tabularFigures,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'El envío y la propina los ves en tu boleta.',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md + MediaQuery.paddingOf(context).bottom),
          child: AppButton(
            label: cart.canCheckout ? 'Continuar' : 'Agrega ${Formatters.money(cart.missingForMinimum)} más',
            trailing: cart.canCheckout
                ? Text(Formatters.money(cart.subtotal), style: const TextStyle(fontFeatures: AppTypography.tabularFigures))
                : null,
            onPressed: cart.canCheckout
                ? () {
                    Navigator.of(context).pop();
                    widget.onCheckout();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

/// Entrada/salida de una fila: crece y aparece (sin movimiento si se pidió).
class _Appear extends StatelessWidget {
  const _Appear({required this.animation, required this.child, super.key});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.postaOut, reverseCurve: AppMotion.postaIn);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.line, this.onDismissed});

  final CartLine line;
  final VoidCallback? onDismissed;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final removed = await ref.read(cartControllerProvider.notifier).remove(line.id);
    if (removed == null || !context.mounted) return;
    AppToast.show(
      context,
      '${line.name} salió de tu bolsa',
      kind: AppToastKind.undo,
      onAction: () => ref.read(cartControllerProvider.notifier).restore(removed),
    );
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final notes = await _editNote(
      context,
      title: 'Nota para este producto',
      label: line.name,
      initial: line.notes,
      hint: 'Ej.: sin cebolla, cremas aparte',
    );
    if (notes != null) await ref.read(cartControllerProvider.notifier).setNotes(line.id, notes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    return Dismissible(
      key: ValueKey('dismiss-${line.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        onDismissed?.call();
        _remove(context, ref).ignore();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: chaski.danger.withValues(alpha: 0.12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quitar', style: theme.textTheme.labelLarge?.copyWith(color: chaski.danger)),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.delete_outline_rounded, color: chaski.danger),
          ],
        ),
      ),
      child: Semantics(
        hint: line.notes.isEmpty ? 'Toca para agregar una nota' : 'Toca para editar la nota',
        child: InkWell(
          onTap: () => _editNotes(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
            child: Row(
              children: [
                AppNetworkImage(url: line.imageUrl, width: 60, height: 60, borderRadius: AppRadius.tile, fallbackIcon: Icons.fastfood_rounded),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (line.description.isNotEmpty)
                        Text(line.description, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      if (line.notes.isNotEmpty)
                        Text(
                          '“${line.notes}”',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: AppSpacing.xxs),
                      AppPrice(line.total, size: 15),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _LineStepper(
                  quantity: line.quantity,
                  onChanged: (q) => ref.read(cartControllerProvider.notifier).setQuantity(line.id, q),
                  onRemove: () => _remove(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stepper compacto: en 1, el "−" se convierte en quitar.
class _LineStepper extends StatelessWidget {
  const _LineStepper({required this.quantity, required this.onChanged, required this.onRemove});

  final Quantity quantity;
  final ValueChanged<Quantity> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atOne = !quantity.canDecrement;
    Widget button(IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.padded),
      onPressed: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick().ignore();
              onTap();
            },
      icon: Icon(icon, size: 18),
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: const BorderRadius.all(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            atOne ? Icons.delete_outline_rounded : Icons.remove_rounded,
            atOne ? 'Quitar' : 'Quitar uno',
            atOne ? onRemove : () => onChanged(quantity.decrement()),
          ),
          SizedBox(
            width: 20,
            child: AnimatedSwitcher(
              duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
              child: Text(
                '${quantity.value}',
                key: ValueKey(quantity.value),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppTypography.tabularFigures),
              ),
            ),
          ),
          button(Icons.add_rounded, 'Agregar uno', quantity.canIncrement ? () => onChanged(quantity.increment()) : null),
        ],
      ),
    );
  }
}

/// "+ Nota para el negocio (opcional)" o la nota ya escrita.
class _StoreNoteRow extends StatelessWidget {
  const _StoreNoteRow({required this.note, required this.onTap});

  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final empty = note.isEmpty;
    return Semantics(
      button: true,
      label: empty ? 'Agregar nota para el negocio, opcional' : 'Nota para el negocio: $note. Editar',
      excludeSemantics: true,
      child: Material(
        color: context.chaski.raised,
        borderRadius: AppRadius.tile,
        child: InkWell(
          borderRadius: AppRadius.tile,
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
                              children: [TextSpan(text: ' (opcional)', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500))],
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
        ),
      ),
    );
  }
}

/// Franja lima suave hacia el pedido mínimo: un objetivo claro en vez de un
/// error al final.
class _MinimumStrip extends StatelessWidget {
  const _MinimumStrip({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    return Semantics(
      label: 'Te faltan ${spokenMoney(cart.missingForMinimum)} para el pedido mínimo',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        decoration: BoxDecoration(color: chaski.accentSoft, borderRadius: AppRadius.tile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: chaski.accent, shape: BoxShape.circle, border: Border.all(color: chaski.onAccent, width: 1.5)),
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
                curve: AppMotion.postaOut,
                builder: (context, p, _) => LinearProgressIndicator(
                  value: p,
                  minHeight: 5,
                  color: chaski.onAccent,
                  backgroundColor: chaski.accent.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponRow extends ConsumerStatefulWidget {
  const _CouponRow();

  @override
  ConsumerState<_CouponRow> createState() => _CouponRowState();
}

class _CouponRowState extends ConsumerState<_CouponRow> {
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
    final coupon = ref.watch(cartControllerProvider).value?.coupon;
    final chaski = context.chaski;

    if (coupon != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Container(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          decoration: BoxDecoration(color: chaski.accent, borderRadius: AppRadius.tile),
          child: Row(
            children: [
              Icon(Icons.local_offer_rounded, color: chaski.onAccent, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('${coupon.code} · ${coupon.label}', style: theme.textTheme.labelLarge?.copyWith(color: chaski.onAccent))),
              IconButton(
                tooltip: 'Quitar cupón',
                color: chaski.onAccent,
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
      curve: AppMotion.postaOut,
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
