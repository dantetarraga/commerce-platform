import 'package:apamuy/core/utils/formatters.dart';
import 'package:apamuy/features/orders/domain/order.dart';
import 'package:apamuy/features/orders/presentation/providers/orders_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calificación breve tras la entrega: cinco estrellas, etiquetas rápidas y
/// una nota opcional para el negocio.
Future<void> showRatingSheet(BuildContext context, Order order) => showAppBottomSheet<void>(
  context,
  builder: (_) => _RatingSheet(order: order),
);

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet({required this.order});

  final Order order;

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  final _comment = TextEditingController();
  int? _rating;
  final _tags = <String>{};
  var _sending = false;

  // Con 4 o 5 estrellas se pregunta qué gustó; con menos, qué falló.
  static const _goodTags = ['Llegó caliente', 'Rápido', 'Amable', 'Buena porción'];
  static const _badTags = ['Llegó frío', 'Tardó mucho', 'Faltó algo', 'Porción pequeña'];

  List<String> get _tagOptions => (_rating ?? 5) >= 4 ? _goodTags : _badTags;
  static const _starLabels = ['Muy mal', 'Mal', 'Regular', 'Bien', '¡Excelente!'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final rating = _rating;
    if (rating == null) return;
    setState(() => _sending = true);
    // Las etiquetas viajan en el comentario hasta que el backend las reciba aparte.
    final comment = [
      if (_tags.isNotEmpty) _tags.join(', '),
      if (_comment.text.trim().isNotEmpty) _comment.text.trim(),
    ].join(' · ');
    final result = await ref.read(ordersRepositoryProvider).rate(widget.order.id, rating: rating, comment: comment);
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      (_) {
        // El seguimiento abierto debajo también debe ver la calificación.
        ref
          ..invalidate(ordersHistoryProvider)
          ..invalidate(orderWatchProvider(widget.order.id));
        Navigator.of(context).pop();
        final who = widget.order.store.ownerName ?? widget.order.store.name;
        AppToast.show(context, 'Gracias. Se lo contamos a $who.', kind: AppToastKind.success);
      },
      (failure) => AppToast.show(context, failure.message, kind: AppToastKind.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final apamuy = context.apamuy;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DeliveredStub(order: widget.order),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text('¿Qué tal estuvo?', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Semantics(
                    button: true,
                    selected: _rating == i,
                    label: '$i de 5 estrellas, ${_starLabels[i - 1]}',
                    excludeSemantics: true,
                    child: InkResponse(
                      radius: 28,
                      onTap: () {
                        HapticFeedback.selectionClick().ignore();
                        setState(() {
                          _rating = i;
                          _tags.removeWhere((t) => !_tagOptions.contains(t));
                        });
                      },
                      child: SizedBox.square(
                        dimension: 52,
                        child: AnimatedScale(
                          scale: _rating == i ? 1.15 : 1,
                          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
                          curve: AppMotion.knot,
                          child: Icon(
                            (_rating ?? 0) >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 42,
                            color: (_rating ?? 0) >= i ? apamuy.rating : scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 20,
              child: AnimatedSwitcher(
                duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
                child: Text(
                  _rating == null ? '' : _starLabels[_rating! - 1],
                  key: ValueKey(_rating),
                  style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (_rating != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _rating! >= 4 ? '¿Qué te gustó?' : '¿Qué falló?',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final tag in _tagOptions)
                  AppChip(
                    label: tag,
                    selected: _tags.contains(tag),
                    onTap: () {
                      HapticFeedback.selectionClick().ignore();
                      setState(() => _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag));
                    },
                  ),
              ],
            ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: 'Para el negocio (opcional)',
              controller: _comment,
              variant: AppInputVariant.note,
              hint: 'Cuéntale algo al negocio',
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: _rating == null ? 'Elige las estrellas' : 'Enviar calificación', loading: _sending, onPressed: _rating == null ? null : _send),
          ],
        ),
      ),
    );
  }
}

/// Talón de la boleta: a qué hora llegó, quién lo preparó y quién lo llevó.
class _DeliveredStub extends StatelessWidget {
  const _DeliveredStub({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final courier = order.courier;
    final at = order.timeOf(OrderStatus.delivered);
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppTypography.tabularFigures);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketEdge(top: true),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.md, AppSpacing.sm),
          child: Row(
            children: [
              AppAvatar(
                imageUrl: courier?.avatarUrl ?? order.store.logoUrl,
                initials: courier?.initials,
                seed: courier?.name,
                variant: courier == null ? AppAvatarVariant.store : AppAvatarVariant.courier,
                fallbackIcon: courier == null ? Icons.storefront_rounded : Icons.person_rounded,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(at == null ? 'Pedido entregado' : 'Llegó a las ${Formatters.clock(at)}', style: theme.textTheme.titleSmall),
                    Text(
                      ['Preparó ${order.store.ownerName ?? order.store.name}', if (courier != null) 'Llevó ${courier.firstName}'].join(' · '),
                      style: muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.money(order.total), style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppTypography.tabularFigures)),
                  Text(order.code, style: muted),
                ],
              ),
            ],
          ),
        ),
        const TicketEdge(top: false),
      ],
    );
  }
}
