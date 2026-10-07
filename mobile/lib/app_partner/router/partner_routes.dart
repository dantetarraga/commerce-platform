/// Paths de Apamuy Socios. Para navegar se usa `context.goNamed(Page.name)`.
abstract final class PartnerRoutePaths {
  static const splash = '/splash';

  // Entrada con celular + código (sin registro: al socio lo da de alta el equipo).
  static const login = '/entrar';
  static const otp = 'codigo'; // hija de /entrar
  static const notPartner = '/no-socio';

  static const merchantHome = '/negocio';
  static const merchantProducts = 'productos/:storeId'; // hija de /negocio
  static const courierHome = '/reparto';
  static const activeDelivery = 'pedido/:orderId'; // hija de /reparto

  /// Rutas accesibles sin sesión (se comparan con el inicio del path).
  static const Set<String> public = {splash, login, notPartner};

  static bool isPublic(String location) => public.any((p) => location == p || location.startsWith('$p/'));

  static bool isUnder(String location, String root) => location == root || location.startsWith('$root/');
}
