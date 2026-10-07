import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/presentation/widgets/store_mappers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Buscador dentro de la carta del negocio (sin importar tildes).
class MenuSearchSheet extends StatefulWidget {
  const MenuSearchSheet({required this.menu, required this.onOpen, super.key});

  final StoreMenu menu;
  final ValueChanged<MenuItem> onOpen;

  @override
  State<MenuSearchSheet> createState() => _MenuSearchSheetState();
}

class _MenuSearchSheetState extends State<MenuSearchSheet> {
  final _controller = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(String value) => setState(() => _query = value);

  @override
  Widget build(BuildContext context) {
    final items = widget.menu.search(_query);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xs),
          child: AppSearchBar(
            variant: AppSearchBarVariant.compact,
            hints: const ['Chairo, gaseosa, pan…'],
            controller: _controller,
            autofocus: true,
            onChanged: _update,
            onSubmitted: _update,
            onClear: () {
              _controller.clear();
              _update('');
            },
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const AppEmptyState(
                  scene: AppEmptyArt.search,
                  title: 'No está en la carta',
                  message: 'Prueba con otra palabra.',
                  compact: true,
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => AppProductCard(
                    data: items[index].toCardData(),
                    onTap: () => widget.onOpen(items[index]),
                  ),
                ),
        ),
      ],
    );
  }
}
