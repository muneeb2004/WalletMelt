class CsvEncoder {
  const CsvEncoder();

  String encodeRows(Iterable<Iterable<Object?>> rows) {
    return rows.map(encodeRow).join('\n');
  }

  String encodeRow(Iterable<Object?> values) {
    return values.map(encodeField).join(',');
  }

  String encodeField(Object? value) {
    if (value == null) return '';

    final text = value.toString();
    final escaped = text.replaceAll('"', '""');
    final shouldQuote = text.contains(',') ||
        text.contains('"') ||
        text.contains('\r') ||
        text.contains('\n');

    return shouldQuote ? '"$escaped"' : escaped;
  }
}
