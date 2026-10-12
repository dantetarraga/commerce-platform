/// API pública del feature `merchant_catalog`: la carta editable del negocio en
/// Apamuy Socios (productos, fotos, secciones e importación desde Excel o CSV).
library;

export 'domain/menu_import.dart' show ImportAction;
export 'presentation/pages/menu_sections_page.dart';
export 'presentation/pages/product_editor_page.dart';
export 'presentation/pages/product_import_page.dart';
export 'presentation/providers/menu_providers.dart' show importHighlightsProvider, menuRevisionProvider;
export 'presentation/widgets/menu_bulk_bar.dart';
export 'presentation/widgets/menu_page_scaffold.dart' show MenuBottomBar;
export 'presentation/widgets/menu_start_options.dart';
export 'presentation/widgets/quick_edit_sheet.dart';
export 'presentation/widgets/quick_photo_button.dart';
