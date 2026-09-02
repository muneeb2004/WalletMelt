/// Tolerant numeric parser that cleans and parses user inputs across all entry fields.
/// 
/// Handles:
/// - Thousand separators with commas: '1,250.50' -> 1250.50, '1,000,000' -> 1000000.0
/// - European comma decimals: '1250,50' -> 1250.50, '1.250,50' -> 1250.50
/// - Space separators: '1 250.50' -> 1250.50
/// - Accidental currency prefixes/suffixes: '$1,200', '€45,99', 'Rs 500', '150 USD' -> 1200.0, 45.99, 500.0, 150.0
/// - Duplicate punctuation typos: '1..50' -> 1.50, '12,,50' -> 12.50
/// - Whitespace and accidental special characters
double? parseTolerantNumber(String? input) {
  if (input == null) return null;
  var text = input.trim();
  if (text.isEmpty) return null;

  // Check negative sign
  final isNegative = text.startsWith('-') || text.contains(r'-$') || text.contains(RegExp(r'\-\s*\d'));

  // Remove abbreviation dots attached to words (e.g. "approx." -> "approx")
  text = text.replaceAll(RegExp(r'(?<=[a-zA-Z])\.(?=\s|$)'), '');

  // Strip all characters except digits, commas, periods, and spaces
  text = text.replaceAll(RegExp(r'[^\d.,\s]'), '').trim();
  if (text.isEmpty) return null;

  // Remove spaces
  text = text.replaceAll(RegExp(r'\s+'), '');

  // Collapse consecutive commas and periods
  text = text.replaceAll(RegExp(r',+'), ',');
  text = text.replaceAll(RegExp(r'\.+'), '.');

  // Strip leading or trailing punctuation (e.g. ".250" or "250.")
  // Note: if user typed ".50", we want 0.50
  if (text.startsWith('.')) text = '0$text';
  if (text.startsWith(',')) text = '0$text';
  text = text.replaceAll(RegExp(r'[.,]+$'), '');

  final hasComma = text.contains(',');
  final hasPeriod = text.contains('.');

  String normalized;
  if (hasComma && hasPeriod) {
    final lastComma = text.lastIndexOf(',');
    final lastPeriod = text.lastIndexOf('.');
    if (lastComma > lastPeriod) {
      // European format: 1.250,50 -> 1250.50
      normalized = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Standard format: 1,250.50 -> 1250.50
      normalized = text.replaceAll(',', '');
    }
  } else if (hasComma && !hasPeriod) {
    final commaCount = ','.allMatches(text).length;
    if (commaCount > 1) {
      // Multiple commas like 1,000,000
      normalized = text.replaceAll(',', '');
    } else {
      final parts = text.split(',');
      if (parts.length == 2 && parts[1].length == 3 && parts[0].length <= 3) {
        // Ambiguous: 1,000 -> 1000 in finance inputs
        normalized = text.replaceAll(',', '');
      } else {
        // Single comma treated as decimal: 1250,50 -> 1250.50
        normalized = text.replaceAll(',', '.');
      }
    }
  } else if (hasPeriod && !hasComma) {
    final periodCount = '.'.allMatches(text).length;
    if (periodCount > 1) {
      // Multiple periods: 1.000.000 -> 1000000
      normalized = text.replaceAll('.', '');
    } else {
      normalized = text;
    }
  } else {
    normalized = text;
  }

  final val = double.tryParse(normalized);
  if (val == null) return null;
  return isNegative ? -val : val;
}
