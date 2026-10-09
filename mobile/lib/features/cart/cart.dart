/// API pública del feature `cart` ("Tu bolsa").
library;

export 'cart_domain.dart';
export 'presentation/add_to_cart.dart';
export 'presentation/providers/cart_providers.dart' show cartControllerProvider, cartItemCountProvider;
export 'presentation/widgets/cart_sheet.dart' show confirmReplaceCart, showCartSheet;
export 'presentation/widgets/note_sheet.dart' show NoteSheet, showNoteSheet;
