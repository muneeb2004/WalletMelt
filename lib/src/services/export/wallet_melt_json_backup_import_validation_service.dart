import 'dart:convert';
import 'wallet_melt_json_backup_validator.dart';

/// The result of import validation.
class BackupValidationResult {
  final bool isValid;
  final String? error;
  final int? expensesCount;
  final int? groceryItemsCount;
  final int? categoriesCount;
  final int? budgetsCount;

  const BackupValidationResult({
    required this.isValid,
    this.error,
    this.expensesCount,
    this.groceryItemsCount,
    this.categoriesCount,
    this.budgetsCount,
  });
}

/// A service to validate and parse backup files without modifying database or state.
class WalletMeltJsonBackupImportValidationService {
  final WalletMeltJsonBackupValidator _validator;

  const WalletMeltJsonBackupImportValidationService({
    WalletMeltJsonBackupValidator validator =
        const WalletMeltJsonBackupValidator(),
  }) : _validator = validator;

  /// Validates the raw JSON string and extracts statistics if valid.
  BackupValidationResult validateBackup(String jsonText) {
    final validation = _validator.validate(jsonText);
    if (!validation.isValid) {
      return BackupValidationResult(
        isValid: false,
        error: validation.error,
      );
    }

    try {
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final expenses = decoded['expenses'] as List;
      final groceryItems = decoded['grocery_items'] as List;
      final categories = decoded['categories'] as List;
      final budgets = decoded['budgets'] as List;

      return BackupValidationResult(
        isValid: true,
        expensesCount: expenses.length,
        groceryItemsCount: groceryItems.length,
        categoriesCount: categories.length,
        budgetsCount: budgets.length,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        error: 'Invalid backup format: $e',
      );
    }
  }
}
