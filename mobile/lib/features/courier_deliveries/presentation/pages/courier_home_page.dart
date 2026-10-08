import 'package:chaski/core/config/city.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/courier_deliveries/domain/courier.dart';
import 'package:chaski/features/courier_deliveries/presentation/pages/active_delivery_page.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/features/courier_deliveries/presentation/widgets/courier_day_ticket.dart';
import 'package:chaski/features/courier_deliveries/presentation/widgets/route_card.dart';
import 'package:chaski/features/orders/orders_staff.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/partner/partner.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _eyebrow = '${brandName.toUpperCase()} SOCIOS · REPARTO';

String _orderId(StaffOrder order) => order.id;

/// La disponibilidad, la siguiente entrega y el cierre de la jornada.
class CourierHomePage extends ConsumerStatefulWidget {
  const CourierHomePage({super.key});

  static const name = 'courierHome';

  @override
  ConsumerState<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends ConsumerState<CourierHomePage> with PartnerActionRunner {
  Future<void> _setOnline(bool online) => run(() => ref.read(courierMeProvider.notifier).setOnline(online: online));

  Future<void> _refresh() async {
    ref
      ..invalidate(courierMeProvider)
      ..invalidate(courierActiveDeliveryProvider)
      ..invalidate(courierAvailableOrdersProvider)
      ..invalidate(courierSummaryProvider);
    await ref.read(courierMeProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(courierMeProvider);
    // Con un pedido en curso, el cliente lo ve llegar en el mapa.
    ref.watch(courierLocationSharingProvider);
    final delivery = ref.watch(courierActiveDeliveryProvider);

    return OrderAlarmScope<StaffOrder>(
      orders: courierAvailableOrdersProvider,
      rule: const OrderAlarmRule.onNew(_orderId),
      keepAwake: me.value?.isOnline ?? false,
      child: Scaffold(
        appBar: partnerStatusBar(context),
        body: SafeArea(
          top: false,
          child: AsyncValueView(
            value: me,
            onRetry: () => ref.invalidate(courierMeProvider),
            loading: const _CourierHomeSkeleton(),
            data: (profile) => RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _CourierHero(
                      profile: profile,
                      pill: PartnerStatusPill(
                        title: profile.isOnline ? 'En ruta · conectado' : 'Desconectado',
                        message: switch (profile.availability) {
                          CourierAvailability.offline => 'Conéctate para ver recorridos',
                          CourierAvailability.available => 'Recibes recorridos en $cityName · ${profile.vehicleLabel}',
                          CourierAvailability.busy => 'Tienes un recorrido en curso',
                        },
                        value: profile.isOnline,
                        busy: busy,
                        onChanged: _setOnline,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: PartnerContent(
                      maxWidth: 720,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 18, AppSpacing.gutter, 0),
                        child: switch (delivery) {
                          AsyncValue(value: final active?) => _ActiveDeliveryBanner(order: active),
                          AsyncValue(hasError: true) || AsyncValue(hasValue: false) => AsyncValueView(
                            value: delivery,
                            compactError: true,
                            onRetry: () => ref.invalidate(courierActiveDeliveryProvider),
                            loading: const RouteCardSkeleton(),
                            data: (_) => const SizedBox.shrink(),
                          ),
                          _ when profile.isOnline => const _AvailableOrders(),
                          _ => const _OfflineNote(),
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: PartnerContent(
                      maxWidth: 720,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, AppSpacing.xl),
                        child: CourierDayTicket(),
                      ),
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

/// "Buenas noches, Luis · Yauri te espera." con su foto y la moto.
class _CourierHero extends ConsumerWidget {
  const _CourierHero({required this.profile, required this.pill});

  final CourierProfile profile;
  final Widget pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider.select((s) => s.value));
    final summary = ref.watch(courierSummaryProvider).value;
    final scheme = Theme.of(context).colorScheme;
    return PartnerHero(
      eyebrow: _eyebrow,
      greeting: '${partnerGreeting()}, ${profile.name.split(' ').first}',
      title: '$cityName te',
      accent: 'espera.',
      subtitleLoading: summary == null,
      subtitle: summary == null
          ? null
          : 'Hoy: ${summary.deliveredCount} ${summary.deliveredCount == 1 ? 'recorrido' : 'recorridos'} · cobraste ${Formatters.money(summary.total)}',
      avatar: SizedBox.square(
        dimension: 130,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: AppAvatar(imageUrl: user?.avatarUrl, initials: user?.initials, seed: user?.id ?? profile.id, size: 106),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: AppRadius.button,
                  border: Border.all(color: scheme.primaryContainer, width: 3),
                ),
                child: const Icon(Icons.two_wheeler_rounded, size: 20, color: AppColors.blanco),
              ),
            ),
          ],
        ),
      ),
      actions: const [PartnerAccountButton()],
      pill: pill,
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: AppRadius.card),
      child: Row(
        children: [
          Icon(Icons.route_rounded, size: 36, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu próximo recorrido empieza aquí', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Al conectarte verás de dónde sale, a dónde llega y cuánto cobras antes de tomarlo.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDeliveryBanner extends StatelessWidget {
  const _ActiveDeliveryBanner({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pickingUp = order.status == OrderStatus.courierAssigned;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TU RECORRIDO EN CURSO · ${order.order.code}',
            style: AppTypography.eyebrow(context).copyWith(color: scheme.primary, letterSpacing: 1.2),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            pickingUp ? 'Recoge en ${order.order.store.name}' : 'Entrega a ${order.customerName}',
            style: theme.textTheme.headlineSmall,
          ),
          Text(
            pickingUp ? order.pickup.address : order.order.addressStreet,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          StaffCollectSummary.compact(order: order.order),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Continuar entrega',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.pushNamed(ActiveDeliveryPage.name, pathParameters: {'orderId': order.id}),
          ),
        ],
      ),
    );
  }
}

class _AvailableOrders extends ConsumerStatefulWidget {
  const _AvailableOrders();

  @override
  ConsumerState<_AvailableOrders> createState() => _AvailableOrdersState();
}

class _AvailableOrdersState extends ConsumerState<_AvailableOrders> with PartnerActionRunner {
  String? _taking;

  Future<void> _accept(StaffOrder order) async {
    setState(() => _taking = order.id);
    final ok = await run(() => ref.read(courierActionsProvider.notifier).accept(order.id));
    if (!mounted) return;
    setState(() => _taking = null);
    if (ok) await context.pushNamed(ActiveDeliveryPage.name, pathParameters: {'orderId': order.id});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = ref.watch(courierAvailableOrdersProvider);
    final list = orders.value ?? const <StaffOrder>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text('Recorridos listos', style: theme.textTheme.headlineSmall)),
            if (list.isNotEmpty)
              Text(
                '${list.length} en $cityName',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (list.isEmpty)
          AsyncValueView(
            value: orders,
            compactError: true,
            onRetry: () => ref.invalidate(courierAvailableOrdersProvider),
            loading: const Column(
              children: [RouteCardSkeleton(), SizedBox(height: AppSpacing.md), RouteCardSkeleton()],
            ),
            data: (_) => const AppEmptyState(
              scene: AppEmptyArt.ride,
              title: 'Nada por ahora',
              message: 'Te avisaremos cuando un negocio tenga un pedido listo.',
            ),
          )
        else
          for (final (i, order) in list.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            RouteCard(
              order: order,
              first: i == 0,
              taking: _taking == order.id,
              onTake: busy ? null : () => _accept(order),
            ),
          ],
      ],
    );
  }
}

/// Inicio mientras llega el perfil: portada, píldora y un recorrido en blanco.
class _CourierHomeSkeleton extends ConsumerWidget {
  const _CourierHomeSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider.select((s) => s.value));
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        PartnerHero(
          eyebrow: _eyebrow,
          greeting: user == null ? null : '${partnerGreeting()}, ${user.firstName}',
          title: '$cityName te',
          accent: 'espera.',
          subtitleLoading: true,
          avatar: Container(
            width: 130,
            height: 130,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: AppAvatar(imageUrl: user?.avatarUrl, initials: user?.initials, seed: user?.id, size: 106),
          ),
          actions: const [PartnerAccountButton()],
          pill: const PartnerStatusPillSkeleton(),
        ),
        const PartnerContent(
          maxWidth: 720,
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 18, AppSpacing.gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: Skeleton(child: SkeletonBox(width: 190, height: 24))),
                SizedBox(height: AppSpacing.sm),
                RouteCardSkeleton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
