/// Paths de la app. Para navegar se usa `context.goNamed(Page.name)`;
/// los paths solo se usan al declarar las rutas y en los redirects.
abstract final class RoutePaths {
  static const splash = '/splash';
  static const onboarding = '/bienvenida';

  // Entrada con celular + código.
  static const login = '/entrar';
  static const otp = 'codigo'; // hija de /entrar
  static const profileSetup = 'nombre'; // hija de /entrar/codigo

  // Shell: Inicio · Buscar · Pedidos · (Bolsa) · Tú.
  static const home = '/cerca';
  static const categoryStores = 'categoria/:categoryId'; // hija de /cerca
  static const explore = '/explorar';
  static const profile = '/tu';
  static const orders = '/pedidos';
  static const favorites = 'favoritos'; // hija de /tu
  static const editProfile = 'datos'; // hija de /tu

  // Detalle a pantalla completa (sobre la barra).
  static const storeDetail = '/negocio/:storeId';
  static const productDetail = '/producto/:productId';
  static const checkout = '/checkout';
  static const orderTracking = '/pedido/:orderId';
  static const orderHelp = 'ayuda'; // hija de /pedido/:orderId
  static const notifications = '/avisos';
  static const addressForm = '/direccion/nueva';

  /// Términos y privacidad: se leen con o sin sesión.
  static const legal = '/legal/:doc';
  static bool isLegal(String location) => location.startsWith('/legal/');

  /// Rutas accesibles sin sesión (se comparan con el inicio del path).
  static const Set<String> public = {splash, onboarding, login};

  static bool isPublic(String location) =>
      public.any((p) => location == p || location.startsWith('$p/'));
}
