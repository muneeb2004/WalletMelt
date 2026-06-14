import 'dart:convert';
import 'wallet_melt_json_backup_validator.dart';

class WalletMeltBackupPreview {
  final bool isValid;
  final String? error;
  final String? format;
  final int? formatVersion;
  final String? exportedAt;
  final String? appVersion;
  final int expensesCount;
  final int deletedExpensesCount;
  final int groceryItemsCount;
  final int categoriesCount;
  final int budgetsCount;
  final bool hasSettings;
  final int receiptImageCount;
  final List<String> warnings;

  const WalletMeltBackupPreview({
    required this.isValid,
    this.error,
    this.format,
    this.formatVersion,
    this.exportedAt,
    this.appVersion,
    this.expensesCount = 0,
    this.deletedExpensesCount = 0,
    this.groceryItemsCount = 0,
    this.categoriesCount = 0,
    this.budgetsCount = 0,
    this.hasSettings = false,
    this.receiptImageCount = 0,
    this.warnings = const [],
  });
}

class WalletMeltJsonBackupPreviewService {
  final WalletMeltJsonBackupValidator _validator;

  const WalletMeltJsonBackupPreviewService({
    WalletMeltJsonBackupValidator validator = const WalletMeltJsonBackupValidator(),
  }) : _validator = validator;

  /// Parses the raw JSON string and generates a read-only preview summary.
  WalletMeltBackupPreview generatePreview(String jsonText) {
    final validation = _validator.validate(jsonText);
    if (!validation.isValid) {
      return WalletMeltBackupPreview(
        isValid: false,
        error: validation.error,
      );
    }

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return const WalletMeltBackupPreview(
          isValid: false,
          error: 'Backup root is not a JSON object.',
        );
      }
      final map = decoded.cast<String, Object?>();

      final metadata = map['metadata'] as Map<String, dynamic>;
      final format = metadata['format'] as String?;
      final formatVersion = metadata['format_version'] as int?;
      final exportedAt = metadata['exported_at'] as String?;
      final appVersion = metadata['app_version'] as String?;

      final expensesList = map['expenses'] as List? ?? [];
      final groceryItemsList = map['grocery_items'] as List? ?? [];
      final categoriesList = map['categories'] as List? ?? [];
      final budgetsList = map['budgets'] as List? ?? [];
      final settingsMap = map['settings'] as Map?;

      int deletedExpensesCount = 0;
      int receiptImageCount = 0;

      for (final exp in expensesList) {
        if (exp is Map) {
          if (exp['deleted_at'] != null) {
            deletedExpensesCount++;
          }
          final receiptUri = exp['receipt_image_uri'];
          if (receiptUri != null && receiptUri.toString().isNotEmpty) {
            receiptImageCount++;
          }
        }
      }

      final warnings = <String>[];
      if (appVersion == null || appVersion.isEmpty) {
        warnings.add('Unknown application version.');
      }
      if (expensesList.isEmpty &&
          groceryItemsList.isEmpty &&
          categoriesList.isEmpty &&
          budgetsList.isEmpty &&
          settingsMap == null) {
        warnings.add('Backup file is empty.');
      }
      if (receiptImageCount > 0) {
        warnings.add(
          'Receipt images are references only. Physical receipt files are not packaged in this backup.',
        );
      }

      return WalletMeltBackupPreview(
        isValid: true,
        format: format,
        formatVersion: formatVersion,
        exportedAt: exportedAt,
        appVersion: appVersion,
        expensesCount: expensesList.length,
        deletedExpensesCount: deletedExpensesCount,
        groceryItemsCount: groceryItemsList.length,
        categoriesCount: categoriesList.length,
        budgetsCount: budgetsList.length,
        hasSettings: settingsMap != null,
        receiptImageCount: receiptImageCount,
        warnings: warnings,
      );
    } catch (e) {
      return WalletMeltBackupPreview(
        isValid: false,
        error: 'Failed to generate preview: $e',
      );
    }
  }
}
