import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/cart/domain/entities/cart.dart';
import 'package:apamuy/features/cart/presentation/providers/cart_providers.dart';
import 'package:apamuy/features/cart/presentation/widgets/cart_line_tile.dart';
import 'package:apamuy/features/cart/presentation/widgets/cart_summary.dart';
import 'package:apamuy/features/cart/presentation/widgets/note_sheet.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre "Tu bolsa" como hoja. [onCheckout] y [onExplore] los provee la app
/// (el feature no conoce rutas).
Future<void> showCartSheet(BuildContext context, {required VoidCallback onCheckout, required VoidCallback onExplore}) {
  return showAppBottomSheet<void>(
    context,
    size: AppSheetSize.full,
    builder: (_) => CartSheet(onCheckout: onCheckout, onExplore: onExplore),
  );
}

/// Pregunta antes de reemplazar una bolsa de otro negocio. `true` = vaciar.
Future<bool> confirmReplaceCart(BuildContext context, {required CartStore current, required CartStore incoming}) => showAppConfirmDialog(
  context,
  title: '¿Empezamos otra bolsa?',
  message: 'Tu bolsa tiene productos de ${current.name}. Para pedir en ${incoming.name} la vaciamos primero.',
  confirmLabel: 'Vaciar y agregar',
  cancelLabel: 'Mantener mi bolsa',
);

class CartSheet extends ConsumerStatefulWidget {
  const CartSheet({required this.onCheckout, required this.onExplore, super.key});

  final VoidCallback onCheckout;
  final VoidCallback onExplore;

  @override
  ConsumerState<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<CartSheet> {
  final _listKey = GlobalKey<SliverAnimatedListState>();

  late List<CartLine> _items = List.of(ref.read(cartControllerProvider).value?.lines ?? const []);

  /// Líneas quitadas deslizando: el Dismissible ya animó su salida.
  final _dismissed = <String>{};

  Duration get _duration => reduceMotionOf(context) ? Duration.zero : AppMotion.base;

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
        (context, animation) => silent
            ? const SizedBox.shrink()
            : _Appear(
                animation: animation,
                child: IgnorePointer(child: CartLineTile(line: old)),
              ),
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
    final controller = ref.read(cartControllerProvider.notifier);
    final note = await showNoteSheet(
      context,
      title: 'Nota para el negocio',
      label: cart.store?.name ?? 'Nota',
      initial: cart.note,
      hint: 'Ej.: sin ají en nada, tocar el timbre',
    );
    if (note != null) await controller.setNote(note);
  }

  Future<void> _lineNotes(CartLine line) async {
    final controller = ref.read(cartControllerProvider.notifier);
    final notes = await showNoteSheet(
      context,
      title: 'Nota para este producto',
      label: line.name,
      initial: line.notes,
      hint: 'Ej.: sin cebolla, cremas aparte',
    );
    if (notes != null) await controller.setNotes(line.id, notes);
  }

  // Vive aquí y no en la fila: la fila se desmonta al salir y el aviso de
  // "Deshacer" necesita un contexto montado.
  Future<void> _remove(CartLine line) async {
    final controller = ref.read(cartControllerProvider.notifier);
    final removed = await controller.remove(line.id);
    if (removed == null || !mounted) return;
    AppToast.show(
      context,
      '${line.name} salió de tu bolsa',
      kind: AppToastKind.undo,
      onAction: () => controller.restore(removed).ignore(),
    );
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
                    Text('TU PRÓXIMA PARADA', style: AppTypography.eyebrow(context)),
                    const SizedBox(height: 6),
                    Semantics(header: true, child: Text('Tu bolsa', style: theme.textTheme.headlineLarge)),
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
                    child: CartLineTile(
                      line: line,
                      onDismissed: () => _dismissed.add(line.id),
                      onRemove: () => _remove(line).ignore(),
                      onQuantityChanged: (q) => ref.read(cartControllerProvider.notifier).setQuantity(line.id, q),
                      onEditNotes: () => _lineNotes(line).ignore(),
                    ),
                  );
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
                sliver: SliverToBoxAdapter(child: CartSummary(cart: cart, onEditNote: () => _storeNote(cart))),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md + MediaQuery.paddingOf(context).bottom),
          child: AppButton(
            label: cart.canCheckout ? 'Continuar' : 'Agrega ${Formatters.money(cart.missingForMinimum)} más',
            trailing: cart.canCheckout ? Text(Formatters.money(cart.subtotal), style: const TextStyle(fontFeatures: AppTypography.tabularFigures)) : null,
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

/// Entrada/salida de una fila: crece y aparece.
class _Appear extends StatelessWidget {
  const _Appear({required this.animation, required this.child, super.key});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.arrive, reverseCurve: AppMotion.depart);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}
