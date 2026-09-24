import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/products/domain/entities/product.dart';
import 'package:chaski/features/products/domain/entities/product_selection.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Título del grupo con su etiqueta a la derecha: "OBLIGATORIO" (gris) hasta
/// que se cumple, "hasta 2" en los opcionales.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.tag, required this.required, required this.fulfilled, this.subtitle});

  final String title;
  final String? subtitle;
  final String tag;
  final bool required;
  final bool fulfilled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chaski = context.chaski;
    final Widget label;
    if (required && fulfilled) {
      label = Row(
        key: const ValueKey('done'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: chaski.success),
          const SizedBox(width: 4),
          Text('Listo', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ],
      );
    } else if (required) {
      label = Container(
        key: const ValueKey('pending'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
        decoration: BoxDecoration(color: chaski.raised, borderRadius: const BorderRadius.all(AppRadius.sm)),
        child: Text(tag, style: AppTypography.eyebrow(context).copyWith(color: scheme.onSurfaceVariant)),
      );
    } else {
      label = Text(tag, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
                if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: CurvedAnimation(parent: animation, curve: AppMotion.knot), child: child),
            child: label,
          ),
        ],
      ),
    );
  }
}

/// Variantes (tamaños, presentaciones): filas de elegir una.
class VariantGroup extends StatelessWidget {
  const VariantGroup({required this.variants, required this.selectedId, required this.onSelected, super.key});

  final List<ProductVariant> variants;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeader(title: 'Elige el tamaño', tag: 'OBLIGATORIO', required: true, fulfilled: selectedId != null),
        for (final v in variants)
          _ChoiceRow(
            label: v.name,
            trailing: Formatters.money(v.price),
            spokenPrice: spokenMoney(v.price),
            selected: v.id == selectedId,
            single: true,
            enabled: v.isAvailable,
            unavailable: !v.isAvailable,
            onTap: () => onSelected(v.id),
          ),
      ],
    );
  }
}

/// Grupo de opciones como filas con borde (una o varias).
class OptionGroup extends StatelessWidget {
  const OptionGroup({required this.option, required this.selection, required this.onToggle, super.key});

  final ProductOption option;
  final ProductSelection selection;
  final ValueChanged<String> onToggle;

  String get _tag {
    if (option.isRequired) return 'OBLIGATORIO';
    return option.isSingleChoice ? 'opcional' : 'hasta ${option.maxSelect}';
  }

  String? get _subtitle {
    if (!option.isRequired || option.isSingleChoice) return null;
    return option.minSelect == option.maxSelect
        ? 'Elige ${option.minSelect}'
        : 'Elige entre ${option.minSelect} y ${option.maxSelect}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = selection.selectedIn(option.id).length;
    final canSelectMore = selection.canSelectMore(option);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeader(
          title: option.name,
          subtitle: _subtitle,
          tag: _tag,
          required: option.isRequired,
          fulfilled: selectedCount >= option.minSelect,
        ),
        for (final value in option.values)
          _ChoiceRow(
            label: value.name,
            trailing: _deltaLabel(value.priceDelta, single: option.isSingleChoice),
            spokenPrice: value.priceDelta.isZero ? null : 'más ${spokenMoney(value.priceDelta)}',
            selected: selection.isSelected(option.id, value.id),
            single: option.isSingleChoice,
            enabled: value.isAvailable && (canSelectMore || selection.isSelected(option.id, value.id) || option.isSingleChoice),
            unavailable: !value.isAvailable,
            onTap: () => onToggle(value.id),
          ),
      ],
    );
  }
}

String _deltaLabel(Money delta, {required bool single}) =>
    delta.isZero ? (single ? 'incluido' : '') : '+ ${Formatters.money(delta)}';

/// Fila con borde. Elegida: borde cobalto y fondo cobalto suave.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.trailing,
    required this.spokenPrice,
    required this.selected,
    required this.single,
    required this.enabled,
    required this.unavailable,
    required this.onTap,
  });

  final String label;
  final String trailing;
  final String? spokenPrice;
  final bool selected;
  final bool single;
  final bool enabled;
  final bool unavailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = !enabled;
    final duration = reduceMotionOf(context) ? Duration.zero : AppMotion.quick;
    return Semantics(
      checked: single ? null : selected,
      selected: single ? selected : null,
      inMutuallyExclusiveGroup: single,
      enabled: enabled,
      label: '$label${spokenPrice == null ? '' : ', $spokenPrice'}${unavailable ? ', agotado' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xs),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.tile,
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick().ignore();
                    onTap();
                  }
                : null,
            child: AnimatedContainer(
              duration: duration,
              curve: AppMotion.postaOut,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : null,
                borderRadius: AppRadius.tile,
                border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  _Mark(selected: selected, single: single, muted: muted, duration: duration),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      unavailable ? '$label · agotado' : label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  if (trailing.isNotEmpty)
                    Text(
                      trailing,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Radio (una) o check (varias), en cobalto al elegir.
class _Mark extends StatelessWidget {
  const _Mark({required this.selected, required this.single, required this.muted, required this.duration});

  final bool selected;
  final bool single;
  final bool muted;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = selected ? scheme.primary : (muted ? scheme.outlineVariant : scheme.outline);
    if (single) {
      return AnimatedContainer(
        duration: duration,
        width: 22,
        height: 22,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: border, width: selected ? 6.5 : 2)),
      );
    }
    return AnimatedContainer(
      duration: duration,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : null,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: border, width: 2),
      ),
      child: selected ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary) : null,
    );
  }
}
