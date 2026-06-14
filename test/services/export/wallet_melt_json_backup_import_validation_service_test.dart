import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_import_validation_service.dart';

void main() {
  group('WalletMeltJsonBackupImportValidationService', () {
    const service = WalletMeltJsonBackupImportValidationService();

    test('accepts valid backup and extracts correct counts', () {
      const validJson = '''
      {
        "metadata": {
          "format": "walletmelt.local_json_backup",
          "format_version": 1,
          "app_version": "1.0.0",
          "exported_at": "2026-06-14T12:00:00Z",
          "includes": ["expenses", "grocery_items", "categories", "budgets", "settings"]
        },
        "expenses": [{"id": "e1", "amount": 100}],
        "grocery_items": [{"id": "g1"}],
        "categories": [{"id": "c1"}, {"id": "c2"}],
        "budgets": [{"id": "b1"}],
        "settings": {}
      }
      ''';

      final result = service.validateBackup(validJson);
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
      expect(result.expensesCount, equals(1));
      expect(result.groceryItemsCount, equals(1));
      expect(result.categoriesCount, equals(2));
      expect(result.budgetsCount, equals(1));
    });

    test('rejects invalid backup from validator', () {
      const invalidJson = '{"invalid": "json"}';
      final result = service.validateBackup(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });

    test('rejects malformed json safely without crashing', () {
      const malformedJson = '{invalid-json';
      final result = service.validateBackup(malformedJson);
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });
  });
}
