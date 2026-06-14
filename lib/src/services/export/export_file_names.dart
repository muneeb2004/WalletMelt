String buildWalletMeltExportFileName({
  required String exportKind,
  required DateTime createdAt,
  String extension = 'csv',
}) {
  final kind = _safeSegment(exportKind);
  final fileExtension = _safeSegment(extension);
  final timestamp = _formatTimestamp(createdAt);
  return 'walletmelt-$kind-$timestamp.$fileExtension';
}

String _safeSegment(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  if (normalized.isEmpty) return 'export';
  return normalized;
}

String _formatTimestamp(DateTime value) {
  return '${_fourDigits(value.year)}${_twoDigits(value.month)}${_twoDigits(value.day)}-'
      '${_twoDigits(value.hour)}${_twoDigits(value.minute)}${_twoDigits(value.second)}';
}

String _fourDigits(int value) => value.toString().padLeft(4, '0');

String _twoDigits(int value) => value.toString().padLeft(2, '0');
