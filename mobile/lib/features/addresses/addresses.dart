/// API pública del feature `addresses`.
library;

export 'domain/address.dart' show Address, AddressKind;
export 'presentation/pages/address_form_page.dart';
export 'presentation/providers/address_providers.dart' show addressBookControllerProvider, selectedAddressProvider;
export 'presentation/widgets/address_picker_sheet.dart' show addressIcon, showAddressPicker;
