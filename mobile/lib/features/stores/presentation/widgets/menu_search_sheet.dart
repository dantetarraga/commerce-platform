import 'dart:async';

import 'package:apamuy/features/stores/domain/entities/store_menu.dart';
import 'package:apamuy/features/stores/presentation/providers/stores_providers.dart';
import 'package:apamuy/features/stores/presentation/widgets/store_mappers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Buscador dentro de la carta del negocio. Busca el backend (sin tildes) un
/// momento después de dejar de escribir.
class MenuSearchSheet extends ConsumerStatefulWidget {
  const MenuSearchSheet({required this.storeId, required this.onOpen, super.key});

  final String storeId;
  final ValueChanged<MenuItem> onOpen;

  @override
  ConsumerState<MenuSearchSheet> createState() => _MenuSearchSheetState();
}

class _MenuSearchSheetState extends ConsumerState<MenuSearchSheet> {
  final _controller = TextEditingController();
  var _query = '';
  Timer? _debounce;

  /// Lo último que respondió el backend: no parpadea mientras llega lo nuevo.
  List<MenuItem>? _last;

  static const _delay = Duration(milliseconds: 300);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _update(String value, {bool now = false}) {
    _debounce?.cancel();
    if (now) {
      setState(() => _query = value.trim());
      return;
    }
    _debounce = Timer(_delay, () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(menuSearchProvider(widget.storeId, _query));
    if (results.value case final items?) _last = items;
    final items = _last;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xs),
          child: AppSearchBar(
            variant: AppSearchBarVariant.compact,
            hints: const ['Chairo, gaseosa, pan…'],
            controller: _controller,
            autofocus: true,
            loading: results.isLoading,
            onChanged: _update,
            onSubmitted: (value) => _update(value, now: true),
            onClear: () {
              _controller.clear();
              _update('', now: true);
            },
          ),
        ),
        Expanded(
          child: switch (items) {
            null when results.hasError => AppEmptyState.fromError(
              results.error!,
              compact: true,
              onRetry: () => ref.invalidate(menuSearchProvider(widget.storeId, _query)),
            ),
            null => const Center(child: AppLoader()),
            [] => const AppEmptyState(
              scene: AppEmptyArt.search,
              title: 'No está en la carta',
              message: 'Prueba con otra palabra.',
              compact: true,
            ),
            final items => ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => AppProductCard(
                data: items[index].toCardData(),
                onTap: () => widget.onOpen(items[index]),
              ),
            ),
          },
        ),
      ],
    );
  }
}
