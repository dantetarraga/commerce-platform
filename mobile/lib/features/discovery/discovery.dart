/// API pública del feature `discovery`: búsqueda (Explorar) y promociones.
library;

export 'domain/moment.dart';
export 'domain/promotion.dart';
export 'domain/search.dart';
export 'presentation/pages/explore_page.dart';
export 'presentation/providers/discovery_providers.dart' show currentMomentProvider, localProductsProvider;
export 'presentation/providers/popular_searches_providers.dart' show popularSearchesProvider;
export 'presentation/providers/promotions_providers.dart' show promotionsProvider;
export 'presentation/providers/search_providers.dart' show searchQueryProvider, searchResultsProvider;
export 'presentation/quick_add_product.dart';
