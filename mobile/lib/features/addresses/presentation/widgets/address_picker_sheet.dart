import 'package:chaski/features/addresses/domain/address.dart';
import 'package:chaski/features/addresses/presentation/pages/address_form_page.dart';
import 'package:chaski/features/addresses/presentation/providers/address_providers.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hoja para elegir dónde llegan los pedidos (sin salir de la pantalla).
Future<void> showAddressPicker(BuildContext context) => showAppBottomSheet<void>(
  context,
  title: '¿Dónde te lo llevamos?',
  builder: (_) => const AddressPicker(),
);

IconData addressIcon(AddressKind kind) => switch (kind) {
  AddressKind.home => Icons.home_rounded,
  AddressKind.work => Icons.work_rounded,
  AddressKind.other => Icons.place_rounded,
};

class AddressPicker extends ConsumerWidget {
  const AddressPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final book = ref.watch(addressBookControllerProvider).value ?? AddressBook.empty;
    final selected = book.selected;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (book.addresses.isEmpty)
              const AppEmptyState(
                compact: true,
                scene: ThreadScene.door,
                title: 'Aún no guardas direcciones',
                message: 'Agrega la primera y los negocios calcularán tiempo y envío hasta tu puerta.',
              ),
            for (final address in book.addresses)
              Semantics(
                selected: address.id == selected?.id,
                button: true,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.tile),
                  selected: address.id == selected?.id,
                  selectedTileColor: theme.colorScheme.primaryContainer,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: context.chaski.raised, shape: BoxShape.circle),
                    child: Icon(addressIcon(address.kind), size: 20),
                  ),
                  title: Text(address.title, style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    [address.street, if (address.reference.isNotEmpty) address.reference].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: address.id == selected?.id ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
                  onTap: () async {
                    HapticFeedback.selectionClick().ignore();
                    await ref.read(addressBookControllerProvider.notifier).select(address.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: 'Agregar dirección',
              icon: Icons.add_location_alt_outlined,
              onPressed: book.isFull
                  ? null
                  : () async {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      await router.pushNamed(AddressFormPage.name);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
