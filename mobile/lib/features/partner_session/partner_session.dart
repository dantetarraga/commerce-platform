/// API pública del feature `partner_session`: quién es socio y en qué modo
/// usa Chaski Socios.
library;

export 'domain/partner_mode.dart' show PartnerMode, availablePartnerModes, resolvePartnerMode;
export 'presentation/pages/not_partner_page.dart';
export 'presentation/providers/partner_mode_providers.dart'
    show activePartnerModeProvider, availablePartnerModesForProvider, partnerModePreferenceProvider;
export 'presentation/widgets/partner_account_button.dart';
