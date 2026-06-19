import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_preview_service.dart';

void main() {
  group('WalletMeltJsonBackupPreviewService', () {
    const previewService = WalletMeltJsonBackupPreviewService();

    test('returns metadata and counts for valid backup', () {
      const validJson = '''
      {
        "metadata": {
          "format": "walletmelt.local_json_backup",
          "format_version": 1,
          "app_version": "0.1.1",
          "exported_at": "2026-06-14T09:08:07.000",
          "includes": ["expenses", "grocery_items", "categories", "budgets", "settings"]
        },
        "expenses": [
          {"id": "exp1", "amount": 100, "currency": "PKR", "category_id": "cat1", "title": "Dinner", "date": "2026-06-14", "is_recurring": false, "created_at": "2026-06-14", "updated_at": "2026-06-14", "deleted_at": null},
          {"id": "exp2", "amount": 200, "currency": "PKR", "category_id": "cat1", "title": "Lunch", "date": "2026-06-14", "is_recurring": false, "created_at": "2026-06-14", "updated_at": "2026-06-14", "deleted_at": "2026-06-15"}
        ],
        "grocery_items": [
          {"id": "item1", "expense_id": "exp1", "name": "Milk", "amount": 50, "created_at": "2026-06-14"}
        ],
        "categories": [
          {"id": "cat1", "name": "Food", "icon": "food", "color": "#FF0000", "is_default": true, "created_at": "2026-06-14", "updated_at": "2026-06-14"}
        ],
        "budgets": [
          {"id": "b1", "category_id": "cat1", "amount": 500, "currency": "PKR", "month": "2026-06", "created_at": "2026-06-14", "updated_at": "2026-06-14"}
        ],
        "settings": {
          "currency": "PKR",
          "theme_preference": "system",
          "has_completed_onboarding": true,
          "last_exported_at": "2026-06-14"
        }
      }
      ''';

      final preview = previewService.generatePreview(validJson);

      expect(preview.isValid, isTrue);
      expect(preview.error, isNull);
      expect(preview.format, 'walletmelt.local_json_backup');
      expect(preview.formatVersion, 1);
      expect(preview.appVersion, '0.1.1');
      expect(preview.exportedAt, '2026-06-14T09:08:07.000');
      expect(preview.expensesCount, 2);
      expect(preview.deletedExpensesCount, 1);
      expect(preview.groceryItemsCount, 1);
      expect(preview.categoriesCount, 1);
      expect(preview.budgetsCount, 1);
      expect(preview.hasSettings, isTrue);
      expect(preview.receiptImageCount, 0);
      expect(preview.warnings, isEmpty);
    });

    test('rejects malformed JSON', () {
      const malformedJson = '{ invalid json }';
      final preview = previewService.generatePreview(malformedJson);

      expect(preview.isValid, isFalse);
      expect(preview.error, contains('Malformed JSON'));
    });

    test('rejects unsupported format/version', () {
      const wrongFormatJson = '''
      {
        "metadata": {
          "format": "unsupported",
          "format_version": 2,
          "exported_at": "2026-06-14",
          "includes": []
        },
        "expenses": [],
        "grocery_items": [],
        "categories": [],
        "budgets": [],
        "settings": null
      }
      ''';
      final preview = previewService.generatePreview(wrongFormatJson);

      expect(preview.isValid, isFalse);
      expect(preview.error, contains('Unsupported format'));
    });

    test('handles empty arrays and produces appropriate warning', () {
      const emptyJson = '''
      {
        "metadata": {
          "format": "walletmelt.local_json_backup",
          "format_version": 1,
          "exported_at": "2026-06-14T09:08:07.000",
          "includes": ["expenses", "grocery_items", "categories", "budgets", "settings"]
        },
        "expenses": [],
        "grocery_items": [],
        "categories": [],
        "budgets": [],
        "settings": null
      }
      ''';

      final preview = previewService.generatePreview(emptyJson);

      expect(preview.isValid, isTrue);
      expect(preview.expensesCount, 0);
      expect(preview.warnings, contains('Backup file is empty.'));
    });

    test('detects receipt image references and issues warning', () {
      const receiptJson = '''
      {
        "metadata": {
          "format": "walletmelt.local_json_backup",
          "format_version": 1,
          "exported_at": "2026-06-14T09:08:07.000",
          "includes": ["expenses", "grocery_items", "categories", "budgets", "settings"]
        },
        "expenses": [
          {"id": "exp1", "amount": 100, "currency": "PKR", "category_id": "cat1", "title": "Dinner", "date": "2026-06-14", "is_recurring": false, "created_at": "2026-06-14", "updated_at": "2026-06-14", "receipt_image_uri": "file:///path/to/img.jpg"}
        ],
        "grocery_items": [],
        "categories": [],
        "budgets": [],
        "settings": null
      }
      ''';

      final preview = previewService.generatePreview(receiptJson);

      expect(preview.isValid, isTrue);
      expect(preview.receiptImageCount, 1);
      expect(
          preview.warnings,
          contains(
              'Receipt images are references only. Physical receipt files are not packaged in this backup.'));
    });
  });
}
