import 'dart:async';

import 'package:chaski/shared/design_system/tokens/app_colors.dart';
import 'package:chaski/shared/design_system/tokens/app_spacing.dart';
import 'package:chaski/shared/design_system/tokens/motion.dart';
import 'package:flutter/material.dart';

enum AppSearchBarVariant {
  /// Protagonista en Cerca: ejemplos que rotan.
  hero,

  /// Cabecera de Explorar.
  compact,
}

/// Buscador. Si [onTap] no es nulo, se comporta como botón (abre Explorar);
/// si hay [controller], es editable.
///
/// [hints] rota ejemplos reales según el momento ("caldo", "pan",
/// "paracetamol"…) cada 3 s, con un fundido corto.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    this.hints = const ['Busca negocios o productos'],
    this.variant = AppSearchBarVariant.hero,
    this.onTap,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    super.key,
  });

  final List<String> hints;
  final AppSearchBarVariant variant;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  Timer? _timer;
  var _hintIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.hints.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) setState(() => _hintIndex = (_hintIndex + 1) % widget.hints.length);
      });
    }
    widget.controller?.addListener(_refresh);
    widget.focusNode?.addListener(_refresh);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller?.removeListener(_refresh);
    widget.focusNode?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hero = widget.variant == AppSearchBarVariant.hero;
    final hint = widget.hints[_hintIndex % widget.hints.length];
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    final hintStyle = theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant);

    final focused = widget.focusNode?.hasFocus ?? false;
    final decoration = BoxDecoration(
      color: focused ? scheme.surface : context.chaski.raised,
      borderRadius: AppRadius.button,
      border: Border.all(color: focused ? scheme.primary : Colors.transparent, width: 2),
    );

    final Widget field = widget.controller == null
        ? AnimatedSwitcher(
            duration: reduceMotionOf(context) ? Duration.zero : AppMotion.base,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: Align(
              key: ValueKey(hint),
              alignment: Alignment.centerLeft,
              child: Text(hint, style: hintStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
        : TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: hintStyle,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          );

    final bar = Container(
      height: hero ? 50 : 48,
      decoration: decoration,
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: scheme.onSurface),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: field),
          if (hasText)
            IconButton(
              tooltip: 'Limpiar',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                widget.controller!.clear();
                widget.onClear?.call();
              },
            )
          else
            const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );

    if (widget.onTap == null) return bar;
    return Semantics(
      button: true,
      label: 'Buscar. Ejemplo: $hint',
      excludeSemantics: true,
      child: PressableScale(
        scale: 0.98,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: hero ? AppRadius.card : const BorderRadius.all(AppRadius.lg),
            child: bar,
          ),
        ),
      ),
    );
  }
}
