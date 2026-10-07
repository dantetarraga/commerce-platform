import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/presentation/providers/popular_searches_providers.dart';
import 'package:chaski/features/discovery/presentation/providers/recent_searches.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _storesLabel(int count) => count == 1 ? '1 negocio' : '$count negocios';

/// Explorar sin búsqueda: RECIENTES (chips con reloj) y LO MÁS PEDIDO EN ESPINAR.
class ExploreIdle extends ConsumerWidget {
  const ExploreIdle({required this.onPick, required this.fallback, super.key});

  final ValueChanged<String> onPick;

  /// Términos del momento si "lo más pedido" no carga.
  final List<String> fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider).value ?? const [];
    final popular = ref.watch(popularSearchesProvider);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (recent.isNotEmpty) ...[
          AppSectionHeader.eyebrow(
            'RECIENTES',
            action: AppButton.ghost(
              label: 'Borrar',
              size: AppButtonSize.sm,
              onPressed: () => ref.read(recentSearchesProvider.notifier).clear(),
            ),
          ),
          Padding(
            padding: AppSpacing.screen,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final q in recent)
                  AppChip(label: q, icon: Icons.schedule_rounded, variant: AppChipVariant.suggestion, onTap: () => onPick(q)),
              ],
            ),
          ),
        ],
        const AppSectionHeader.eyebrow('LO MÁS PEDIDO EN ESPINAR'),
        switch (popular) {
          AsyncValue(:final value?) => Column(
            children: [
              for (final p in value) _PopularRow(search: p, onTap: () => onPick(p.term)),
            ],
          ),
          AsyncError() => Padding(
            padding: AppSpacing.screen,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final term in fallback)
                  AppChip(label: term, icon: Icons.trending_up_rounded, variant: AppChipVariant.suggestion, onTap: () => onPick(term)),
              ],
            ),
          ),
          _ => const Skeleton(child: Column(children: [_PopularRowSkeleton(), _PopularRowSkeleton(), _PopularRowSkeleton(), _PopularRowSkeleton()])),
        },
      ],
    );
  }
}

/// Término de "lo más pedido" y en cuántos negocios está.
class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.search, required this.onTap});

  final PopularSearch search;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppTapSurface(
      semanticLabel: '${search.term}, en ${_storesLabel(search.storeCount)}',
      borderRadius: BorderRadius.zero,
      pressScale: 1,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs + 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: context.chaski.raised, borderRadius: AppRadius.tile),
              child: Icon(Icons.trending_up_rounded, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(search.term, style: theme.textTheme.titleSmall),
                  Text('en ${_storesLabel(search.storeCount)}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularRowSkeleton extends StatelessWidget {
  const _PopularRowSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs + 2),
    child: Row(
      children: [
        SkeletonBox(width: 44, height: 44),
        SizedBox(width: AppSpacing.sm),
        SkeletonBox(width: 160),
      ],
    ),
  );
}

/// Sin resultados: el aviso y algunas búsquedas populares para seguir.
class ExploreNoResults extends ConsumerWidget {
  const ExploreNoResults({required this.query, required this.onPick, super.key});

  final String query;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = (ref.watch(popularSearchesProvider).value ?? const []).take(4).map((p) => p.term).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        children: [
          AppEmptyState(
            kind: AppEmptyKind.noResults,
            title: 'No encontramos “$query”',
            message: 'Todavía no hay negocios que lo vendan cerca. Prueba con otra palabra o mira lo más pedido.',
          ),
          if (suggestions.isNotEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final s in suggestions)
                    AppChip(label: s.toLowerCase(), variant: AppChipVariant.suggestion, onTap: () => onPick(s)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
