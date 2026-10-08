import 'package:apamuy/features/partner_session/domain/partner_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sin roles de socio no hay modo', () {
    final modes = availablePartnerModes(isMerchant: false, isCourier: false);
    expect(resolvePartnerMode(modes, PartnerMode.merchant), isNull);
  });

  test('con un solo rol entra en ese modo aunque haya elegido otro', () {
    final modes = availablePartnerModes(isMerchant: false, isCourier: true);
    expect(resolvePartnerMode(modes, PartnerMode.merchant), PartnerMode.courier);
  });

  test('con los dos roles respeta lo elegido y por defecto entra como negocio', () {
    final modes = availablePartnerModes(isMerchant: true, isCourier: true);
    expect(resolvePartnerMode(modes, PartnerMode.courier), PartnerMode.courier);
    expect(resolvePartnerMode(modes, null), PartnerMode.merchant);
  });
}
