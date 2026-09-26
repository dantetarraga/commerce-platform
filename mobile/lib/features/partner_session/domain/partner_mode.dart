/// Modo en el que se usa Chaski Socios. Un socio puede tener los dos roles
/// (por ejemplo, el dueño de una bodega que también reparte).
enum PartnerMode { merchant, courier }

/// Modos disponibles según los roles del usuario, en orden de preferencia.
List<PartnerMode> availablePartnerModes({required bool isMerchant, required bool isCourier}) => [
  if (isMerchant) PartnerMode.merchant,
  if (isCourier) PartnerMode.courier,
];

/// El modo elegido si el usuario todavía tiene ese rol; si no, el primero
/// disponible. `null` si no es socio.
PartnerMode? resolvePartnerMode(List<PartnerMode> available, PartnerMode? preferred) {
  if (available.isEmpty) return null;
  return preferred != null && available.contains(preferred) ? preferred : available.first;
}
