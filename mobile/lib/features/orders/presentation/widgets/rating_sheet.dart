import 'package:chaski/features/orders/domain/order.dart';
import 'package:chaski/features/orders/presentation/providers/orders_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
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

  static const _tagOptions = ['Llegó caliente', 'Rápido', 'Amable', 'Buena porción'];
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
        ref.invalidate(ordersHistoryProvider);
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
    final chaski = context.chaski;
    final courier = widget.order.courier;
    final subtitle = [widget.order.store.name, if (courier != null) 'entregado por ${courier.firstName}'].join(' · ');

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: AppAvatar(
                imageUrl: courier?.avatarUrl ?? widget.order.store.logoUrl,
                initials: courier?.name.split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join(),
                seed: courier?.name,
                variant: courier == null ? AppAvatarVariant.store : AppAvatarVariant.courier,
                size: 56,
                fallbackIcon: courier == null ? Icons.storefront_rounded : Icons.person_rounded,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              header: true,
              child: Text('¿Qué tal estuvo?', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
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
                        setState(() => _rating = i);
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
                            color: (_rating ?? 0) >= i ? chaski.rating : scheme.surfaceContainerHighest,
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
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final tag in _tagOptions)
                  _TagChip(
                    label: tag,
                    selected: _tags.contains(tag),
                    onTap: () => setState(() => _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _comment,
              maxLength: 200,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Cuéntale algo al negocio (opcional)', counterText: ''),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Enviar', loading: _sending, onPressed: _rating == null ? null : _send),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta con borde; seleccionada pasa a cobalto suave.
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick().ignore();
          onTap();
        },
        borderRadius: const BorderRadius.all(AppRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: AnimatedContainer(
            duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : scheme.surface,
              borderRadius: const BorderRadius.all(AppRadius.pill),
              border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[Icon(Icons.check_rounded, size: 16, color: scheme.primary), const SizedBox(width: 4)],
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: selected ? scheme.primary : scheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
