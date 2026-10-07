/// Momento del día: en Espinar se pide por momentos (el desayuno, el menú del
/// mediodía, la noche fría), no solo por categorías.
enum Moment {
  breakfast,
  lunch,
  afternoon,
  night;

  static Moment at(DateTime time) => switch (time.hour) {
    >= 5 && < 11 => breakfast,
    >= 11 && < 15 => lunch,
    >= 15 && < 19 => afternoon,
    _ => night,
  };

  /// Etiqueta de los negocios que destacan en este momento (`StoreSummary.tags`).
  String get tag => switch (this) {
    breakfast => 'desayuno',
    lunch => 'almuerzo',
    afternoon => 'tarde',
    night => 'noche',
  };

  String get greeting => switch (this) {
    breakfast => 'Buenos días',
    lunch || afternoon => 'Buenas tardes',
    night => 'Buenas noches',
  };

  /// Pregunta bajo el saludo.
  String get question => switch (this) {
    breakfast => '¿Pan calientito o algo para el desayuno?',
    lunch => '¿Ya almorzaste?',
    afternoon => '¿Un lonche?',
    night => '¿Algo calientito?',
  };

  /// Título de la colección del momento.
  String get collectionTitle => switch (this) {
    breakfast => 'Para empezar el día',
    lunch => 'Menú del día cerca de ti',
    afternoon => 'Para el lonche',
    night => 'Noche fría: caldos y algo caliente',
  };

  /// Términos de ejemplo del momento ("pan chuta", "caldo").
  List<String> get searchTerms => switch (this) {
    breakfast => const ['pan chuta', 'queso fresco', 'café de altura', 'leche'],
    lunch => const ['menú del día', 'caldo de cordero', 'pollo a la brasa', 'trucha'],
    afternoon => const ['torta de chocolate', 'bizcocho', 'yogurt', 'café'],
    night => const ['caldo', 'pizza', 'paracetamol', 'hamburguesa'],
  };

  /// Ejemplos que rotan en el buscador: "Busca pan chuta".
  List<String> get searchHints => [for (final term in searchTerms) 'Busca $term'];

  /// Categorías que crecen en el estante en este momento (por `slug`).
  List<String> get featuredCategories => switch (this) {
    breakfast => const ['mercado', 'postres'],
    lunch => const ['restaurantes', 'mercado'],
    afternoon => const ['postres', 'regalos'],
    night => const ['restaurantes', 'farmacia'],
  };
}
