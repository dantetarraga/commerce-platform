import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/presentation/providers/menu_providers.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lo que se hace con varios productos elegidos de la lista: agotar, volver a
/// ofrecer o mover de sección (p. ej. «se acabó el pollo»: los cuatro tamaños).
class MenuBulkBar extends ConsumerStatefulWidget {
  const MenuBulkBar({required this.storeId, required this.productIds, required this.onDone, super.key});

  final String storeId;
  final List<String> productIds;

  /// Después de aplicar un cambio: la lista sale del modo de elegir.
  final VoidCallback onDone;

  @override
  ConsumerState<MenuBulkBar> createState() => _MenuBulkBarState();
}

class _MenuBulkBarState extends ConsumerState<MenuBulkBar> with PartnerActionRunner {
  String _products(int n) => n == 1 ? '1 producto' : '$n productos';

  Future<void> _apply(BulkChange change, String done) async {
    HapticFeedback.mediumImpact().ignore();
    final ok = await run(
      () => ref.read(menuActionsProvider.notifier).applyToProducts(widget.productIds, change),
      success: done,
    );
    if (ok) widget.onDone();
  }

  Future<void> _move() async {
    final menu = await ref.read(storeMenuProvider(widget.storeId).future);
    if (!mounted) return;
    final target = await showAppBottomSheet<MoveToSection>(
      context,
      title: 'Mover a…',
      subtitle: _products(widget.productIds.length),
      builder: (context) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          children: [
            for (final section in menu.sections)
              ListTile(
                minTileHeight: AppSpacing.minTouch + 4,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                leading: const Icon(Icons.folder_outlined),
                title: Text(section.name),
                onTap: () => Navigator.pop(context, MoveToSection(section.id)),
              ),
            ListTile(
              minTileHeight: AppSpacing.minTouch + 4,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('Sin sección'),
              onTap: () => Navigator.pop(context, const MoveToSection(null)),
            ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    final name = menu.sections.where((s) => s.id == target.sectionId).firstOrNull?.name;
    await _apply(target, name == null ? 'Quedaron sin sección.' : 'Movidos a $name.');
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.productIds.length;
    final none = n == 0 || busy;
    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(
            label: 'Agotar',
            size: AppButtonSize.md,
            onPressed: none
                ? null
                : () => _apply(const SetAvailable(available: false), '${_products(n)} marcados agotados.'),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: AppButton.secondary(
            label: 'Reponer',
            size: AppButtonSize.md,
            onPressed: none
                ? null
                : () => _apply(const SetAvailable(available: true), '${_products(n)} disponibles otra vez.'),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: AppButton(label: 'Mover', size: AppButtonSize.md, loading: busy, onPressed: none ? null : _move),
        ),
      ],
    );
  }
}
