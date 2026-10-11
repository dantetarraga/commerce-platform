import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/shared/design_system/components/app_ticket.dart';
import 'package:apamuy/shared/design_system/tokens/app_colors.dart';
import 'package:apamuy/shared/design_system/tokens/app_spacing.dart';
import 'package:apamuy/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Lo que se acaba de agregar a la bolsa. [id] distingue un agregado de otro.
final class PurchaseReceipt {
  const PurchaseReceipt({required this.id, required this.at, required this.title, required this.price, this.detail});

  final int id;
  final DateTime at;

  /// "2 × Pollo a la brasa ¼".
  final String title;

  /// "Pierna · Papas nativas".
  final String? detail;
  final Money price;
}

/// Sobre [child] (la barra de compra o el menú inferior) sale una boleta con el
/// último producto agregado, como de una ticketera, y vuelve a guardarse.
/// Solo se imprime en la pantalla visible: si el producto se agregó desde otra
/// (el detalle que se cierra al agregar), sale al volver, si fue hace poco.
class AppReceiptSlot extends StatefulWidget {
  const AppReceiptSlot({required this.receipt, required this.child, super.key});

  final PurchaseReceipt? receipt;
  final Widget child;

  /// Cuánto tiempo después de agregar todavía vale la pena mostrarla.
  static const freshFor = Duration(seconds: 1);

  @override
  State<AppReceiptSlot> createState() => _AppReceiptSlotState();
}

class _AppReceiptSlotState extends State<AppReceiptSlot> with SingleTickerProviderStateMixin {
  /// Parte de la boleta que queda escondida detrás de la barra.
  static const tuck = 14.0;

  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..addStatusListener((status) {
      if (status.isCompleted && mounted) setState(() => _shown = null);
    });
  late Animation<double> _reveal = _revealFor(reduce: false);
  PurchaseReceipt? _shown;
  int? _handledId;

  // Sale rápido y frenando, se queda a la vista y se guarda acelerando.
  Animation<double> _revealFor({required bool reduce}) => TweenSequence<double>([
    TweenSequenceItem(
      tween: reduce ? ConstantTween<double>(1) : Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Easing.emphasizedDecelerate)),
      weight: 14,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: 68),
    TweenSequenceItem(
      tween: reduce ? ConstantTween<double>(0) : Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Easing.emphasizedAccelerate)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(0), weight: 3),
  ]).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePrint();
  }

  @override
  void didUpdateWidget(AppReceiptSlot old) {
    super.didUpdateWidget(old);
    if (old.receipt?.id != widget.receipt?.id) _maybePrint();
  }

  void _maybePrint() {
    final receipt = widget.receipt;
    if (receipt == null || receipt.id == _handledId) return;
    // Tapada por otra pantalla o una hoja: espera a quedar a la vista.
    if (!TickerMode.valuesOf(context).enabled || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _handledId = receipt.id;
    if (DateTime.now().difference(receipt.at) > AppReceiptSlot.freshFor) return;
    _reveal = _revealFor(reduce: reduceMotionOf(context));
    _shown = receipt;
    _controller.forward(from: 0).ignore();
    SemanticsService.sendAnnouncement(View.of(context), 'Agregado: ${receipt.title}', Directionality.of(context)).ignore();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Alto cero: la boleta se dibuja hacia arriba, sobre la pantalla, sin moverla.
        if (shown != null)
          SizedBox(
            height: 0,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              maxHeight: double.infinity,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    // Asoma desde atrás de la barra: el borde de corte sale primero.
                    child: Transform.translate(
                      offset: const Offset(0, tuck),
                      child: SizeTransition(sizeFactor: _reveal, alignment: Alignment.topCenter, child: _Receipt(receipt: shown)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.receipt});

  final PurchaseReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = context.apamuy.success;
    final detail = receipt.detail;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x262A1A14), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TicketEdge(top: true),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.md, AppSpacing.md + _AppReceiptSlotState.tuck),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 22, color: success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Agregado a tu bolsa', style: theme.textTheme.labelSmall?.copyWith(color: success, fontWeight: FontWeight.w700)),
                      Text(receipt.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                      if (detail != null)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  Formatters.money(receipt.price),
                  style: theme.textTheme.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
