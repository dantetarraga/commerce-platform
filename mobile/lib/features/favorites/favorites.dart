/// API pública del feature `favorites`: negocios y productos guardados.
library;

export 'domain/favorites.dart' show FavoriteKind, Favorites;
export 'presentation/pages/favorites_page.dart';
export 'presentation/providers/favorites_providers.dart'
    show FavoritesController, favoritesProvider, isFavoriteProductProvider, isFavoriteStoreProvider;
export 'presentation/toggle_favorite.dart';
export 'presentation/widgets/favorite_toggle.dart';
