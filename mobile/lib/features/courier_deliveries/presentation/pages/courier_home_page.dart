import 'package:chaski/core/alarm/order_alarm.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/courier_deliveries/domain/courier.dart';
import 'package:chaski/features/courier_deliveries/presentation/pages/active_delivery_page.dart';
import 'package:chaski/features/courier_deliveries/presentation/providers/courier_providers.dart';
import 'package:chaski/features/orders/orders_staff.dart';
import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:chaski/shared/widgets/partner_brand.dart';
import 'package:chaski/shared/widgets/partner_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// La disponibilidad, la siguiente entrega y el cierre de la jornada.
class CourierHomePage extends ConsumerStatefulWidget {
  const CourierHomePage({super.key});

  static const name = 'courierHome';

  @override
  ConsumerState<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends ConsumerState<CourierHomePage> {
  late final OrderAlarm _alarm;
  final Set<String> _seen = {};
  var _changingAvailability = false;

  @override
  void initState() {
    super.initState();
    _alarm = ref.read(orderAlarmProvider);
  }

  @override
  void dispose() {
    _alarm
      ..silence().ignore()
      ..keepAwake(on: false).ignore();
    super.dispose();
  }

  Future<void> _setOnline(bool online) async {
    setState(() => _changingAvailability = true);
    final failure = await ref.read(courierMeProvider.notifier).setOnline(online: online);
    if (!mounted) return;
    setState(() => _changingAvailability = false);
    if (failure != null) {
      AppToast.show(context, failure.message, kind: AppToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(
        courierMeProvider,
        (_, next) => _alarm.keepAwake(on: next.value?.isOnline ?? false).ignore(),
      )
      ..listen(courierAvailableOrdersProvider, (_, next) {
        final orders = next.value;
        if (orders == null) return;
        final fresh = orders.any((o) => !_seen.contains(o.id));
        _seen.addAll(orders.map((o) => o.id));
        if (orders.isEmpty) {
          _alarm.silence().ignore();
        } else if (fresh) {
          _alarm.ring().ignore();
        }
      });

    final me = ref.watch(courierMeProvider);
    final delivery = ref.watch(courierActiveDeliveryProvider);

    return Scaffold(
      appBar: partnerStatusBar(context),
      body: SafeArea(
        top: false,
        child: AsyncValueView(
          value: me,
          onRetry: () => ref.invalidate(courierMeProvider),
          loading: const _CourierHomeSkeleton(),
          data: (profile) => RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(courierMeProvider)
                ..invalidate(courierActiveDeliveryProvider)
                ..invalidate(courierAvailableOrdersProvider)
                ..invalidate(courierSummaryProvider);
              await ref.read(courierMeProvider.future);
            },
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
                        CourierAvailability.available => 'Recibes recorridos en Yauri · ${profile.vehicleLabel}',
                        CourierAvailability.busy => 'Tienes un recorrido en curso',
                      },
                      value: profile.isOnline,
                      busy: _changingAvailability,
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
                          loading: const _RouteCardSkeleton(),
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
                      child: _TodaySummary(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Buenas noches, Luis · Yauri te espera." con su foto, la moto y el trazo.
class _CourierHero extends ConsumerWidget {
  const _CourierHero({required this.profile, required this.pill});

  final CourierProfile profile;
  final Widget pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).value;
    final summary = ref.watch(courierSummaryProvider).value;
    final scheme = Theme.of(context).colorScheme;
    return PartnerHero(
      eyebrow: 'CHASKI SOCIOS · REPARTO',
      greeting: '${partnerGreeting()}, ${profile.name.split(' ').first}',
      title: 'Yauri te',
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
              padding: const EdgeInsets.all(12),
              child: AppAvatar(
                imageUrl: user?.avatarUrl,
                initials: user?.initials,
                seed: user?.id ?? profile.id,
                size: 106,
              ),
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
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w800),
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
          _CollectLeader(order: order),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Continuar entrega',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.pushNamed(
              ActiveDeliveryPage.name,
              pathParameters: {'orderId': order.id},
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cobras · Yape ········ S/ 28.50" sobre fondo de campo.
class _CollectLeader extends StatelessWidget {
  const _CollectLeader({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payment = order.order.payment;
    final how = payment is CashPayment && payment.changeFor != null
        ? 'Efectivo · paga con ${Formatters.money(payment.changeFor!)}'
        : payment.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
      child: Row(
        children: [
          Expanded(
            child: Text('Cobras · $how', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(Formatters.money(order.order.total), style: AppTypography.price(context)),
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

class _AvailableOrdersState extends ConsumerState<_AvailableOrders> {
  String? _taking;

  Future<void> _accept(StaffOrder order) async {
    setState(() => _taking = order.id);
    final failure = await ref.read(courierActionsProvider.notifier).accept(order.id);
    if (!mounted) return;
    setState(() => _taking = null);
    if (failure != null) {
      AppToast.show(context, failure.message, kind: AppToastKind.error);
      return;
    }
    await context.pushNamed(
      ActiveDeliveryPage.name,
      pathParameters: {'orderId': order.id},
    );
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
                '${list.length} en Yauri',
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
              children: [
                _RouteCardSkeleton(),
                SizedBox(height: AppSpacing.md),
                _RouteCardSkeleton(),
              ],
            ),
            data: (_) => const AppEmptyState(
              title: 'Nada por ahora',
              message: 'Te avisaremos cuando un negocio tenga un pedido listo.',
            ),
          )
        else
          for (final (i, order) in list.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _RouteCard(
              order: order,
              first: i == 0,
              taking: _taking == order.id,
              onTake: _taking == null ? () => _accept(order) : null,
            ),
          ],
      ],
    );
  }
}

/// Un recorrido: sale del negocio (foto) y llega a la casa por el trazo punteado.
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.order, required this.first, required this.taking, required this.onTake});

  final StaffOrder order;
  final bool first;
  final bool taking;
  final VoidCallback? onTake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = theme.textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800);
    final place = TextStyle(
      fontFamily: AppTypography.display,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
      height: 1.2,
    );
    final meters = order.distanceMeters;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: first ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 44,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: scheme.primary, width: 2),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: AppNetworkImage(
                                url: order.order.store.logoUrl,
                                width: 38,
                                height: 38,
                                borderRadius: const BorderRadius.all(Radius.circular(19)),
                                fallbackIcon: Icons.storefront_rounded,
                              ),
                            ),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: TrackLine(vertical: true),
                              ),
                            ),
                            const StationNode(icon: Icons.home_rounded, color: AppColors.hierba, size: 28),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 84),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SALE DE · ${staffTimeAgo(order.order.placedAt).toUpperCase()}',
                                  style: label?.copyWith(color: scheme.primary),
                                ),
                                Text(order.order.store.name, style: place),
                                Text(order.pickup.address, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'LLEGA A · ${meters < 1000 ? '$meters m' : Formatters.distance(meters / 1000)}',
                            style: label?.copyWith(color: AppColors.hierba),
                          ),
                          Text(order.order.addressStreet, style: place),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Semantics(
                  label: 'Ganas ${Formatters.money(order.order.deliveryFee)}',
                  excludeSemantics: true,
                  child: PartnerStamp('+${Formatters.money(order.order.deliveryFee)}', color: AppColors.hierba, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CollectLeader(order: order),
          const SizedBox(height: 12),
          AppButton(
            label: 'Tomar recorrido',
            icon: Icons.arrow_forward_rounded,
            loading: taking,
            onPressed: onTake,
          ),
        ],
      ),
    );
  }
}

/// La jornada como boleta de rendición: lo cobrado por medio y el efectivo en mano.
class _TodaySummary extends ConsumerWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    return AsyncValueView(
      value: ref.watch(courierSummaryProvider),
      compactError: true,
      onRetry: () => ref.invalidate(courierSummaryProvider),
      loading: const _TodaySummarySkeleton(),
      data: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tu jornada de hoy', style: theme.textTheme.headlineSmall),
          Text(
            '${summary.deliveredCount} ${summary.deliveredCount == 1 ? 'entrega completada' : 'entregas completadas'}',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          const TicketEdge(top: true),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RENDICIÓN DEL DÍA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const PartnerStamp('PARA RENDIR', size: 11),
                  ],
                ),
                const SizedBox(height: 8),
                for (final (label, amount) in [('Yape', summary.yape), ('Plin', summary.plin), ('Efectivo', summary.cash)]) ...[
                  LeaderRow(
                    label: Text(label, style: row),
                    value: Text(Formatters.money(amount), style: row),
                  ),
                  const SizedBox(height: 6),
                ],
                LeaderRow(
                  label: Text('Total cobrado', style: row?.copyWith(fontWeight: FontWeight.w800)),
                  value: Text(Formatters.money(summary.total), style: row?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const TicketPerforation(),
          TicketSection(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: LeaderRow(
              label: Text('Efectivo en mano', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              value: Text(Formatters.money(summary.cash), style: AppTypography.price(context, size: 26)),
            ),
          ),
          const TicketEdge(top: false),
        ],
      ),
    );
  }
}

/// Inicio del repartidor mientras llega su perfil: la portada, la píldora y los
/// recorridos en blanco, en el mismo lugar donde aparecerán.
class _CourierHomeSkeleton extends ConsumerWidget {
  const _CourierHomeSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).value;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        PartnerHero(
          eyebrow: 'CHASKI SOCIOS · REPARTO',
          greeting: user == null ? null : '${partnerGreeting()}, ${user.firstName}',
          title: 'Yauri te',
          accent: 'espera.',
          subtitleLoading: true,
          avatar: Container(
            width: 130,
            height: 130,
            padding: const EdgeInsets.all(12),
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
                _RouteCardSkeleton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Recorrido en blanco: foto, trazo y casa a la izquierda; de dónde sale y a dónde
/// llega; el cobro y el botón.
class _RouteCardSkeleton extends StatelessWidget {
  const _RouteCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: AppRadius.card),
      child: Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 128,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 44,
                    child: Column(
                      children: [
                        const SkeletonBox.circle(size: 44),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: TrackLine(vertical: true, color: context.chaski.shimmerBase),
                          ),
                        ),
                        const SkeletonBox.circle(size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonBox(width: 110, height: 10),
                                  SizedBox(height: 6),
                                  SkeletonBox(width: 130, height: 18),
                                  SizedBox(height: 6),
                                  SkeletonBox(width: 120, height: 12),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            SkeletonBox(width: 70, height: 28, borderRadius: AppRadius.tile),
                          ],
                        ),
                        Spacer(),
                        SkeletonBox(width: 90, height: 10),
                        SizedBox(height: 6),
                        SkeletonBox(width: 150, height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SkeletonBox(height: 46, borderRadius: AppRadius.tile),
            const SizedBox(height: 12),
            const SkeletonBox(height: 52, borderRadius: AppRadius.button),
          ],
        ),
      ),
    );
  }
}

/// La boleta de rendición en blanco: el mismo papel, con bloques por medio de pago.
class _TodaySummarySkeleton extends StatelessWidget {
  const _TodaySummarySkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row(double label) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SkeletonBox(width: label),
          const Spacer(),
          const SkeletonBox(width: 64),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Skeleton(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [SkeletonBox(width: 190, height: 24), SizedBox(height: 8), SkeletonBox(width: 150)],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const TicketEdge(top: true),
        TicketSection(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: Skeleton(
            child: Column(
              children: [
                const Row(
                  children: [
                    SkeletonBox(width: 120, height: 10),
                    Spacer(),
                    SkeletonBox(width: 86, height: 22, borderRadius: AppRadius.tile),
                  ],
                ),
                const SizedBox(height: 12),
                row(50),
                row(40),
                row(70),
                row(100),
              ],
            ),
          ),
        ),
        const TicketPerforation(),
        const TicketSection(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Skeleton(child: Row(children: [SkeletonBox(width: 120), Spacer(), SkeletonBox(width: 100, height: 26)])),
        ),
        const TicketEdge(top: false),
      ],
    );
  }
}
