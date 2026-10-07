/// API pública del feature `stores`.
library;

export 'domain/entities/category.dart';
export 'domain/entities/store_filter.dart';
export 'domain/entities/store_query.dart' show StoreSort, StoreSortLabel;
export 'domain/entities/store_summary.dart';
export 'presentation/pages/category_stores_page.dart';
export 'presentation/pages/store_detail_page.dart';
export 'presentation/providers/stores_providers.dart' show categoriesProvider, storeDetailProvider, storesProvider;
export 'presentation/widgets/category_visuals.dart';
export 'presentation/widgets/store_mappers.dart';
