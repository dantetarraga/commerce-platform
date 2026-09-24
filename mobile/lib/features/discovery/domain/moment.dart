/// Momento del día: en Espinar se pide por momentos (el desayuno, el menú del
/// mediodía, la noche fría), no solo por categorías. Ordena lo que Cerca
/// muestra primero.
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

  /// Ejemplos que rotan en el buscador.
  List<String> get searchHints => switch (this) {
    breakfast => const ['Busca pan chuta', 'Busca queso fresco', 'Busca café de altura', 'Busca leche'],
    lunch => const ['Busca menú del día', 'Busca caldo de cordero', 'Busca pollo a la brasa', 'Busca trucha'],
    afternoon => const ['Busca torta de chocolate', 'Busca bizcocho', 'Busca yogurt', 'Busca café'],
    night => const ['Busca caldo', 'Busca pizza', 'Busca paracetamol', 'Busca hamburguesa'],
  };

  /// Categorías que crecen en el estante en este momento (por `slug`).
  List<String> get featuredCategories => switch (this) {
    breakfast => const ['mercado', 'postres'],
    lunch => const ['restaurantes', 'mercado'],
    afternoon => const ['postres', 'regalos'],
    night => const ['restaurantes', 'farmacia'],
  };
}
