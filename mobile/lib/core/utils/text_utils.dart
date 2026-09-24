const _accents = {
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
  'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
};

/// Minúsculas y sin tildes, para búsquedas: "Ají" → "aji".
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    buffer.write(_accents[char] ?? char.toLowerCase());
  }
  return buffer.toString().trim();
}
