import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/export_file_writer.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_service.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  group('WalletMeltJsonBackupService', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory =
          await Directory.systemTemp.createTemp('walletmelt_json_backup_');
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('writes JSON backup file with expected metadata', () async {
      const service = WalletMeltJsonBackupService(appVersion: '0.1.1+2');

      final result = await service.createBackup(
        expenses: [_expense()],
        groceryItems: [_groceryItem()],
        categories: [_category()],
        budgets: [_budget()],
        settings: _settings(),
        exportedAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final decoded = jsonDecode(await File(result.path).readAsString())
          as Map<String, Object?>;
      final metadata = decoded['metadata'] as Map<String, Object?>;

      expect(result.fileName, 'walletmelt-backup-20260614-090807.json');
      expect(result.mimeType, ExportFileWriter.jsonMimeType);
      expect(metadata['app_version'], '0.1.1+2');
      expect(metadata['exported_at'], '2026-06-14T09:08:07.000');
    });

    test('includes active and deleted expenses supplied by caller', () async {
      const service = WalletMeltJsonBackupService();

      final result = await service.createBackup(
        expenses: [
          _expense(id: 'active'),
          _expense(id: 'deleted', deletedAt: '2026-06-15T00:00:00.000'),
        ],
        groceryItems: [_groceryItem()],
        categories: [_category()],
        budgets: [_budget()],
        settings: _settings(),
        exportedAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final decoded = jsonDecode(await File(result.path).readAsString())
          as Map<String, Object?>;
      final expenses = decoded['expenses'] as List<Object?>;

      expect(expenses, hasLength(2));
      expect(
        expenses.map((expense) => (expense as Map<String, Object?>)['id']),
        ['active', 'deleted'],
      );
    });

    test('includes grocery items and budgets supplied by caller', () async {
      const service = WalletMeltJsonBackupService();

      final result = await service.createBackup(
        expenses: [_expense()],
        groceryItems: [_groceryItem(id: 'milk_item', name: 'Milk')],
        categories: [_category()],
        budgets: [_budget(id: 'june_budget', amount: 30000)],
        settings: _settings(),
        exportedAt: DateTime(2026, 6, 14, 9, 8, 7),
        directory: tempDirectory,
      );

      final decoded = jsonDecode(await File(result.path).readAsString())
          as Map<String, Object?>;
      final groceryItems = decoded['grocery_items'] as List<Object?>;
      final budgets = decoded['budgets'] as List<Object?>;

      expect(
        (groceryItems.single as Map<String, Object?>)['id'],
        'milk_item',
      );
      expect(
        (budgets.single as Map<String, Object?>)['id'],
        'june_budget',
      );
    });
  });
}

Category _category() {
  return const Category(
    id: 'grocery',
    name: 'Groceries',
    icon: 'shopping_basket',
    color: '#000000',
    isDefault: true,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
  );
}

Expense _expense({
  String id = 'expense_1',
  String? deletedAt,
}) {
  return Expense(
    id: id,
    amount: 1200,
    currency: 'PKR',
    categoryId: 'grocery',
    title: 'Grocery',
    date: '2026-06-14T00:00:00.000',
    isRecurring: false,
    createdAt: '2026-06-14T10:00:00.000',
    updatedAt: '2026-06-14T10:00:00.000',
    deletedAt: deletedAt,
  );
}

GroceryItem _groceryItem({
  String id = 'grocery_item_1',
  String expenseId = 'expense_1',
  String name = 'Milk',
}) {
  return GroceryItem(
    id: id,
    expenseId: expenseId,
    name: name,
    amount: 520,
    createdAt: '2026-06-14T10:00:00.000',
  );
}

CategoryBudget _budget({
  String id = 'budget_1',
  double amount = 30000,
}) {
  return CategoryBudget(
    id: id,
    categoryId: 'grocery',
    amount: amount,
    currency: 'PKR',
    month: '2026-06',
    createdAt: '2026-06-01T00:00:00.000',
    updatedAt: '2026-06-01T00:00:00.000',
  );
}

WalletMeltSettings _settings() {
  return WalletMeltSettings.defaults.copyWith(
    hasCompletedOnboarding: true,
  );
}
