import 'package:chaski/core/utils/debouncer.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:chaski/features/discovery/presentation/providers/recent_searches.dart';
import 'package:chaski/features/discovery/presentation/providers/search_providers.dart';
import 'package:chaski/features/discovery/presentation/widgets/explore_idle.dart';
import 'package:chaski/features/discovery/presentation/widgets/search_results_view.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/widgets/async_value_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  static const name = 'explore';

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) => _debouncer.run(() => ref.read(searchQueryProvider.notifier).update(value));

  void _search(String value) {
    _controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    ref.read(searchQueryProvider.notifier).update(value);
    ref.read(recentSearchesProvider.notifier).add(value).ignore();
    _focus.unfocus();
  }

  void _remember() => ref.read(recentSearchesProvider.notifier).add(_controller.text).ignore();

  @override
  Widget build(BuildContext context) {
    final moment = ref.watch(currentMomentProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final results = ref.watch(searchResultsProvider);
    final searching = query.length >= SearchCatalog.minQueryLength;
    // Con resultados previos, se atenúan mientras llegan los nuevos.
    final refreshing = searching && results.isLoading && results.hasValue;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sigue tu antojo.', style: Theme.of(context).textTheme.headlineLarge),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xs),
              child: AppSearchBar(
                variant: AppSearchBarVariant.compact,
                hints: const ['Negocios, platos o productos'],
                controller: _controller,
                focusNode: _focus,
                autofocus: query.isEmpty,
                onChanged: _onChanged,
                onSubmitted: _search,
                onClear: () => _search(''),
                loading: searching && results.isLoading,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: LoadCrossFade(
                stateKey: searching ? 'results' : 'idle',
                child: !searching
                    ? ExploreIdle(onPick: _search, fallback: moment.searchTerms)
                    : AsyncValueView(
                        value: results,
                        onRetry: () => ref.invalidate(searchResultsProvider),
                        loading: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [for (var i = 0; i < 6; i++) const AppProductRowSkeleton()],
                        ),
                        isEmpty: (r) => r.isEmpty,
                        empty: ExploreNoResults(query: query, onPick: _search),
                        data: (r) => AnimatedOpacity(
                          opacity: refreshing ? 0.45 : 1,
                          duration: reduceMotionOf(context) ? Duration.zero : AppMotion.quick,
                          child: IgnorePointer(
                            ignoring: refreshing,
                            child: SearchResultsView(key: ValueKey(query), results: r, onOpen: _remember),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
