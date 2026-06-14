import 'dart:convert';

/// Result of backup JSON validation.
class WalletMeltJsonBackupValidationResult {
  final bool isValid;
  final String? error;

  const WalletMeltJsonBackupValidationResult.valid()
      : isValid = true,
        error = null;

  const WalletMeltJsonBackupValidationResult.invalid(this.error)
      : isValid = false;
}

/// A read-only validator for validating an already-generated JSON structure.
/// This validator does not mutate any data.
class WalletMeltJsonBackupValidator {
  const WalletMeltJsonBackupValidator();

  WalletMeltJsonBackupValidationResult validate(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'Backup root is not a JSON object.');
      }

      final map = decoded.cast<String, Object?>();

      // Check required top-level keys
      final requiredKeys = [
        'metadata',
        'expenses',
        'grocery_items',
        'categories',
        'budgets',
        'settings'
      ];
      for (final key in requiredKeys) {
        if (!map.containsKey(key)) {
          return WalletMeltJsonBackupValidationResult.invalid(
              'Missing required top-level key: $key');
        }
      }

      // Validate metadata
      final metadata = map['metadata'];
      if (metadata is! Map) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'Metadata is not a JSON object.');
      }
      final metadataMap = metadata.cast<String, Object?>();

      // Validate format
      final format = metadataMap['format'];
      if (format != 'walletmelt.local_json_backup') {
        return WalletMeltJsonBackupValidationResult.invalid(
            'Unsupported format: $format');
      }

      // Validate format_version
      final formatVersion = metadataMap['format_version'];
      if (formatVersion is! int) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'Format version is not an integer.');
      }
      if (formatVersion != 1) {
        return WalletMeltJsonBackupValidationResult.invalid(
            'Unsupported format version: $formatVersion');
      }

      // Validate that arrays are indeed arrays
      if (map['expenses'] is! List) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'expenses is not an array.');
      }
      if (map['grocery_items'] is! List) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'grocery_items is not an array.');
      }
      if (map['categories'] is! List) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'categories is not an array.');
      }
      if (map['budgets'] is! List) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'budgets is not an array.');
      }

      // Validate settings is object or null
      final settings = map['settings'];
      if (settings != null && settings is! Map) {
        return const WalletMeltJsonBackupValidationResult.invalid(
            'settings is neither null nor a JSON object.');
      }

      return const WalletMeltJsonBackupValidationResult.valid();
    } on FormatException catch (e) {
      return WalletMeltJsonBackupValidationResult.invalid(
          'Malformed JSON: ${e.message}');
    } catch (e) {
      return WalletMeltJsonBackupValidationResult.invalid(
          'Unexpected parsing error: $e');
    }
  }
}
