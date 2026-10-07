import 'package:chaski/core/config/theme_mode_provider.dart';
import 'package:chaski/core/domain/phone_number.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/addresses/addresses.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/favorites/favorites.dart';
import 'package:chaski/features/notifications/notifications.dart';
import 'package:chaski/features/orders/orders_customer.dart';
import 'package:chaski/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:chaski/features/profile/presentation/providers/profile_summary.dart';
import 'package:chaski/features/profile/presentation/widgets/theme_mode_sheet.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Versión que se muestra al pie; el build la pasa con `--dart-define=APP_VERSION=…`.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

/// "Tú": pedidos, direcciones, pagos, favoritos y ajustes.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const name = 'profile';

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Cerrar sesión?',
      message: 'Tu bolsa se queda guardada en este celular. Para pedir tendrás que entrar de nuevo.',
      confirmLabel: 'Cerrar sesión',
      destructive: true,
    );
    // El router redirige a la entrada cuando la sesión queda vacía.
    if (confirmed) await ref.read(authSessionProvider.notifier).logout();
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) async {
    final picked = await showThemeModeSheet(context, current: current);
    if (picked != null) await ref.read(appThemeModeProvider.notifier).set(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).value;
    final summary = ref.watch(profileSummaryProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final addresses = summary.addressCount;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xxl),
          children: [
            if (user != null)
              Row(
                children: [
                  AppAvatar(imageUrl: user.avatarUrl, initials: user.initials, seed: user.id, size: 64),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(user.fullName, style: theme.textTheme.headlineSmall)),
                        Text(
                          '+51 ${PhoneNumber.displayOf(user.phone.value)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar tus datos',
                    style: IconButton.styleFrom(backgroundColor: context.chaski.raised),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.pushNamed(EditProfilePage.name),
                  ),
                ],
              ),
            if (summary.orderCount > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _Stat(value: '${summary.orderCount}', label: summary.orderCount == 1 ? 'pedido' : 'pedidos'),
                  ),
                  if (summary.favoriteCount > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _Stat(value: '${summary.favoriteCount}', label: summary.favoriteCount == 1 ? 'favorito' : 'favoritos'),
                    ),
                  ],
                  if (!summary.saved.isZero) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: _Stat(value: Formatters.shortMoney(summary.saved), label: 'ahorrado')),
                  ],
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppGroupedCard(
              children: [
                AppGroupedRow(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Mis pedidos',
                  trailing: summary.activeCount == 0 ? null : AppCinta('${summary.activeCount} EN CURSO', dense: true),
                  onTap: () => context.goNamed(OrdersPage.name),
                ),
                AppGroupedRow(
                  icon: Icons.place_outlined,
                  title: 'Direcciones',
                  subtitle: addresses == 0 ? 'Agrega dónde te llevamos los pedidos' : '$addresses guardada${addresses == 1 ? '' : 's'}',
                  onTap: () => showAddressPicker(context),
                ),
                AppGroupedRow(
                  icon: Icons.credit_card_rounded,
                  title: 'Pagos',
                  subtitle: 'Yape, Plin o efectivo al recibir',
                  onTap: () => AppToast.show(context, 'Eliges cómo pagar en cada pedido. Recordamos el último.'),
                ),
                AppGroupedRow(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Favoritos',
                  onTap: () => context.pushNamed(FavoritesPage.name),
                ),
                AppGroupedRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Avisos',
                  onTap: () => context.pushNamed(NotificationsPage.name),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppGroupedCard(
              children: [
                AppGroupedRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tema',
                  subtitle: themeModeLabel(themeMode),
                  onTap: () => _pickTheme(context, ref, themeMode),
                ),
                AppGroupedRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Ayuda',
                  subtitle: 'Problemas con un pedido, pagos o tu cuenta',
                  // Con pedidos, la ayuda arranca desde el más reciente.
                  onTap: () {
                    if (summary.latestOrderId case final orderId?) {
                      context.pushNamed(OrderHelpPage.name, pathParameters: {'orderId': orderId}).ignore();
                    } else {
                      AppToast.show(context, 'Muy pronto: ayuda por WhatsApp con alguien de aquí.');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.ghost(
              label: 'Cerrar sesión',
              icon: Icons.logout_rounded,
              expand: true,
              onPressed: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Column(
                children: [
                  const BrandLogo(size: 24),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Hecho en Espinar · v$appVersion', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
        child: Column(
          children: [
            Text(value, style: AppTypography.price(context)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
