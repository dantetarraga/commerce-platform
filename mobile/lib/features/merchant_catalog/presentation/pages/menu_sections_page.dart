import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/presentation/providers/menu_providers.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/menu_page_scaffold.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/section_name_dialog.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Las secciones de la carta ("Pollos", "Bebidas"): ordenar arrastrando, crear,
/// renombrar y quitar.
class MenuSectionsPage extends ConsumerStatefulWidget {
  const MenuSectionsPage({required this.storeId, super.key});

  static const name = 'menuSections';
  final String storeId;

  @override
  ConsumerState<MenuSectionsPage> createState() => _MenuSectionsPageState();
}

class _MenuSectionsPageState extends ConsumerState<MenuSectionsPage> with PartnerActionRunner {
  MenuActions get _actions => ref.read(menuActionsProvider.notifier);

  /// El orden mientras se guarda: la lista no salta de vuelta antes de que
  /// llegue la carta nueva.
  List<MenuSection>? _pending;

  Future<void> _create() async {
    final name = await showSectionNameDialog(context, title: 'Nueva sección');
    if (name == null) return;
    await run(
      () async => switch (await _actions.createSection(widget.storeId, name)) {
        Ok() => null,
        Err(:final failure) => failure,
      },
      success: 'Sección creada.',
    );
  }

  Future<void> _rename(MenuSection section) async {
    final name = await showSectionNameDialog(context, title: 'Renombrar sección', initial: section.name);
    if (name == null || name == section.name) return;
    await run(() => _actions.renameSection(section.id, name), success: 'Sección renombrada.');
  }

  Future<void> _remove(MenuSection section, int products) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Quitar sección',
      message: products == 0
          ? '«${section.name}» saldrá de la carta.'
          : '«${section.name}» saldrá de la carta. Sus $products productos siguen en la carta, sin sección.',
      confirmLabel: 'Quitar',
      destructive: true,
    );
    if (!confirmed) return;
    await run(() => _actions.removeSection(section.id), success: 'Sección quitada.');
  }

  Future<void> _move(List<MenuSection> sections, int from, int to) async {
    final order = [...sections];
    final moved = order.removeAt(from);
    order.insert(to, moved);
    HapticFeedback.lightImpact().ignore();
    setState(() => _pending = order);
    await run(() => _actions.reorderSections(widget.storeId, [for (final s in order) s.id]));
    if (mounted) setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = storeMenuProvider(widget.storeId);
    final menu = ref.watch(provider);
    final theme = Theme.of(context);
    return MenuPageScaffold(
      title: 'Secciones ',
      accent: 'de la carta.',
      bottom: AppButton(
        label: 'Nueva sección',
        icon: Icons.add_rounded,
        onPressed: busy ? null : _create,
      ),
      body: switch (menu) {
        AsyncValue(:final value?) when value.sections.isEmpty => const AppEmptyState(
          scene: AppEmptyArt.menu,
          title: 'Sin secciones',
          message: 'Agrupa tu carta en secciones como «Pollos» o «Bebidas».',
        ),
        AsyncValue(:final value?) => () {
          final sections = _pending ?? value.sections;
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xl),
            buildDefaultDragHandles: false,
            header: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
              child: Text(
                sections.length > 1
                    ? 'Arrastra desde el ícono de la izquierda para cambiar el orden en que el cliente las ve.'
                    : 'Con dos o más secciones podrás cambiar su orden.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            itemCount: sections.length,
            onReorderStart: (_) => HapticFeedback.mediumImpact().ignore(),
            onReorderItem: busy ? (_, _) {} : (from, to) => _move(sections, from, to),
            proxyDecorator: (child, _, _) => Material(
              color: Colors.transparent,
              elevation: 6,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
              borderRadius: AppRadius.tile,
              child: child,
            ),
            itemBuilder: (context, i) {
              final section = sections[i];
              final products = value.productsIn(section.id);
              return Padding(
                key: ValueKey(section.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _SectionRow(
                  index: i,
                  section: section,
                  products: products,
                  canDrag: sections.length > 1 && !busy,
                  onRename: busy ? null : () => _rename(section),
                  onRemove: busy ? null : () => _remove(section, products),
                ),
              );
            },
          );
        }(),
        AsyncValue(:final error?) => AppEmptyState.fromError(error, onRetry: () => ref.invalidate(provider)),
        _ => const Center(child: AppLoader(semanticsLabel: 'Cargando las secciones')),
      },
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.index,
    required this.section,
    required this.products,
    required this.canDrag,
    required this.onRename,
    required this.onRemove,
  });

  final int index;
  final MenuSection section;
  final int products;
  final bool canDrag;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return PartnerSurface(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxs, AppSpacing.xxs, AppSpacing.xxs, AppSpacing.xxs),
      child: Row(
        children: [
          if (canDrag)
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: 'Mover ${section.name}',
                child: SizedBox.square(
                  dimension: AppSpacing.minTouch,
                  child: Icon(Icons.drag_indicator_rounded, color: muted),
                ),
              ),
            )
          else
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.name, style: theme.textTheme.titleSmall),
                Text(
                  switch (products) {
                    0 => 'Sin productos: el cliente no la ve',
                    1 => '1 producto',
                    _ => '$products productos',
                  },
                  style: theme.textTheme.bodySmall?.copyWith(color: products == 0 ? theme.colorScheme.error : muted),
                ),
              ],
            ),
          ),
          PopupMenuButton<VoidCallback>(
            tooltip: 'Opciones de ${section.name}',
            enabled: onRename != null,
            onSelected: (action) => action(),
            icon: const Icon(Icons.more_horiz_rounded),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: onRename,
                child: const ListTile(leading: Icon(Icons.edit_outlined), title: Text('Renombrar')),
              ),
              PopupMenuItem(
                value: onRemove,
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  title: Text('Quitar', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
