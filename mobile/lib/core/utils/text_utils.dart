const _accents = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ë': 'e', 'í': 'i', 'ì': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ú': 'u', 'ù': 'u', 'ü': 'u', 'ñ': 'n',
  'Á': 'a', 'À': 'a', 'Ä': 'a', 'É': 'e', 'È': 'e', 'Ë': 'e', 'Í': 'i', 'Ì': 'i', 'Ï': 'i',
  'Ó': 'o', 'Ò': 'o', 'Ö': 'o', 'Ú': 'u', 'Ù': 'u', 'Ü': 'u', 'Ñ': 'n',
};

/// Minúsculas y sin tildes ni diéresis, para comparar textos sin que importe
/// cómo se escribieron: "Ají de Gallina" → "aji de gallina". No recorta espacios.
String foldAccents(String input) {
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    buffer.write(_accents[char] ?? char.toLowerCase());
  }
  return buffer.toString();
}

/// [foldAccents] sin espacios a los lados, para búsquedas: " Ají " → "aji".
String normalizeForSearch(String input) => foldAccents(input).trim();
