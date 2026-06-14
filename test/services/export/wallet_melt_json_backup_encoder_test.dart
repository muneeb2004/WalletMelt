import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_encoder.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  group('WalletMeltJsonBackupEncoder', () {
    test('emits deterministic backup shape with metadata', () {
      const encoder = WalletMeltJsonBackupEncoder();

      final json = encoder.encode(
        expenses: [
          _expense(id: 'expense_b', title: 'B'),
          _expense(id: 'expense_a', title: 'A'),
        ],
        groceryItems: [
          _groceryItem(id: 'item_b', expenseId: 'expense_b'),
          _groceryItem(id: 'item_a', expenseId: 'expense_a'),
        ],
        categories: [
          _category(id: 'z', name: 'Utilities'),
          _category(id: 'a', name: 'Groceries'),
        ],
        budgets: [
          _budget(id: 'budget_b', categoryId: 'z', month: '2026-07'),
          _budget(id: 'budget_a', categoryId: 'a', month: '2026-06'),
        ],
        settings: _settings(),
        exportedAt: DateTime(2026, 6, 14, 9, 8, 7),
        appVersion: '0.1.1+2',
      );
      final decoded = jsonDecode(json) as Map<String, Object?>;

      expect(
          decoded.keys,
          orderedEquals([
            'metadata',
            'expenses',
            'grocery_items',
            'categories',
            'budgets',
            'settings',
          ]));
      expect(decoded['metadata'], {
        'format': WalletMeltJsonBackupEncoder.format,
        'format_version': WalletMeltJsonBackupEncoder.formatVersion,
        'app_version': '0.1.1+2',
        'exported_at': '2026-06-14T09:08:07.000',
        'includes': [
          'expenses',
          'grocery_items',
          'categories',
          'budgets',
          'settings',
        ],
      });
      expect(
        ((decoded['expenses'] as List<Object?>).first
            as Map<String, Object?>)['id'],
        'expense_a',
      );
      expect(
        ((decoded['categories'] as List<Object?>).first
            as Map<String, Object?>)['id'],
        'a',
      );
      expect(
        ((decoded['grocery_items'] as List<Object?>).first
            as Map<String, Object?>)['id'],
        'item_a',
      );
      expect(
        ((decoded['budgets'] as List<Object?>).first
            as Map<String, Object?>)['id'],
        'budget_a',
      );
    });

    test('preserves expense fields and null values', () {
      const encoder = WalletMeltJsonBackupEncoder();

      final json = encoder.encode(
        expenses: [
          _expense(
            vendor: null,
            notes: null,
            receiptImageUri: null,
            deletedAt: null,
          ),
        ],
        groceryItems: const [],
        categories: [_category()],
        budgets: const [],
        settings: _settings(lastExportedAt: null),
        exportedAt: DateTime(2026, 6, 14, 9, 8, 7),
      );
      final decoded = jsonDecode(json) as Map<String, Object?>;
      final expense =
          (decoded['expenses'] as List<Object?>).single as Map<String, Object?>;
      final settings = decoded['settings'] as Map<String, Object?>;

      expect(expense['vendor'], isNull);
      expect(expense['notes'], isNull);
      expect(expense['receipt_image_uri'], isNull);
      expect(expense['deleted_at'], isNull);
      expect(settings['last_exported_at'], isNull);
    });

    test('is deterministic for the same inputs', () {
      const encoder = WalletMeltJsonBackupEncoder();
      final exportedAt = DateTime(2026, 6, 14, 9, 8, 7);

      final first = encoder.encode(
        expenses: [_expense(id: 'b'), _expense(id: 'a')],
        groceryItems: [
          _groceryItem(id: 'grocery_b', expenseId: 'b'),
          _groceryItem(id: 'grocery_a', expenseId: 'a'),
        ],
        categories: [_category(id: 'b'), _category(id: 'a')],
        budgets: [
          _budget(id: 'budget_b', categoryId: 'b', month: '2026-07'),
          _budget(id: 'budget_a', categoryId: 'a', month: '2026-06'),
        ],
        settings: _settings(),
        exportedAt: exportedAt,
      );
      final second = encoder.encode(
        expenses: [_expense(id: 'a'), _expense(id: 'b')],
        groceryItems: [
          _groceryItem(id: 'grocery_a', expenseId: 'a'),
          _groceryItem(id: 'grocery_b', expenseId: 'b'),
        ],
        categories: [_category(id: 'a'), _category(id: 'b')],
        budgets: [
          _budget(id: 'budget_a', categoryId: 'a', month: '2026-06'),
          _budget(id: 'budget_b', categoryId: 'b', month: '2026-07'),
        ],
        settings: _settings(),
        exportedAt: exportedAt,
      );

      expect(first, second);
    });

    test('handles empty inputs gracefully producing valid backup structure',
        () {
      const encoder = WalletMeltJsonBackupEncoder();
      final exportedAt = DateTime(2026, 6, 14, 9, 8, 7);

      final json = encoder.encode(
        expenses: [],
        groceryItems: [],
        categories: [],
        budgets: [],
        settings: _settings(lastExportedAt: null),
        exportedAt: exportedAt,
        appVersion: '0.1.0',
      );

      final decoded = jsonDecode(json) as Map<String, Object?>;

      // Verify structure integrity
      expect(decoded['expenses'], isEmpty);
      expect(decoded['grocery_items'], isEmpty);
      expect(decoded['categories'], isEmpty);
      expect(decoded['budgets'], isEmpty);
      expect(decoded['settings'], isNotNull);
      expect(decoded['metadata'], isNotNull);

      // Verify machine-readable JSON structure
      expect(decoded['metadata'], {
        'format': 'walletmelt.local_json_backup',
        'format_version': 1,
        'app_version': '0.1.0',
        'exported_at': '2026-06-14T09:08:07.000',
        'includes': [
          'expenses',
          'grocery_items',
          'categories',
          'budgets',
          'settings',
        ],
      });
    });

    test('verifies deterministic ordering rules for grocery items', () {
      const encoder = WalletMeltJsonBackupEncoder();
      final exportedAt = DateTime(2026, 6, 14, 9, 8, 7);

      // Sorting rules: expenseId first, then createdAt, then id.
      final item1 = _groceryItem(
          id: 'c', expenseId: 'exp_a', createdAt: '2026-06-14T12:00:00.000');
      final item2 = _groceryItem(
          id: 'b', expenseId: 'exp_a', createdAt: '2026-06-14T10:00:00.000');
      final item3 = _groceryItem(
          id: 'a', expenseId: 'exp_b', createdAt: '2026-06-14T09:00:00.000');
      final item4 = _groceryItem(
          id: 'd', expenseId: 'exp_a', createdAt: '2026-06-14T10:00:00.000');

      final json = encoder.encode(
        expenses: [],
        groceryItems: [item1, item2, item3, item4],
        categories: [],
        budgets: [],
        settings: _settings(),
        exportedAt: exportedAt,
      );

      final decoded = jsonDecode(json) as Map<String, Object?>;
      final groceryList = decoded['grocery_items'] as List<Object?>;

      // Expect order:
      // 1. exp_a, 2026-06-14T10:00:00.000, id 'b' (item2)
      // 2. exp_a, 2026-06-14T10:00:00.000, id 'd' (item4)
      // 3. exp_a, 2026-06-14T12:00:00.000, id 'c' (item1)
      // 4. exp_b, 2026-06-14T09:00:00.000, id 'a' (item3)
      final orderedIds = groceryList
          .map((e) => (e as Map<String, Object?>)['id'] as String)
          .toList();

      expect(orderedIds, orderedEquals(['b', 'd', 'c', 'a']));
    });

    test('verifies deterministic ordering rules for budgets', () {
      const encoder = WalletMeltJsonBackupEncoder();
      final exportedAt = DateTime(2026, 6, 14, 9, 8, 7);

      // Sorting rules: month first, then categoryId, then id.
      final budget1 = _budget(id: 'b3', categoryId: 'cat_b', month: '2026-07');
      final budget2 = _budget(id: 'b1', categoryId: 'cat_b', month: '2026-06');
      final budget3 = _budget(id: 'b2', categoryId: 'cat_a', month: '2026-06');
      final budget4 = _budget(id: 'b4', categoryId: 'cat_b', month: '2026-07');

      final json = encoder.encode(
        expenses: [],
        groceryItems: [],
        categories: [],
        budgets: [budget1, budget2, budget3, budget4],
        settings: _settings(),
        exportedAt: exportedAt,
      );

      final decoded = jsonDecode(json) as Map<String, Object?>;
      final budgetsList = decoded['budgets'] as List<Object?>;

      // Expect order:
      // 1. 2026-06, cat_a (budget3)
      // 2. 2026-06, cat_b (budget2)
      // 3. 2026-07, cat_b, id b3 (budget1)
      // 4. 2026-07, cat_b, id b4 (budget4)
      final orderedIds = budgetsList
          .map((e) => (e as Map<String, Object?>)['id'] as String)
          .toList();

      expect(orderedIds, orderedEquals(['b2', 'b1', 'b3', 'b4']));
    });

    test('preserves receipt URI/path exactly as text', () {
      const encoder = WalletMeltJsonBackupEncoder();
      final exportedAt = DateTime(2026, 6, 14, 9, 8, 7);

      const uri1 = 'content://media/external/images/media/123';
      const uri2 = 'file:///var/mobile/Containers/Data/Application/receipt.png';

      final json = encoder.encode(
        expenses: [
          _expense(id: 'e1', receiptImageUri: uri1),
          _expense(id: 'e2', receiptImageUri: uri2),
        ],
        groceryItems: [],
        categories: [],
        budgets: [],
        settings: _settings(),
        exportedAt: exportedAt,
      );

      final decoded = jsonDecode(json) as Map<String, Object?>;
      final expensesList = decoded['expenses'] as List<Object?>;

      final exp1 = expensesList
              .firstWhere((e) => (e as Map<String, Object?>)['id'] == 'e1')
          as Map<String, Object?>;
      final exp2 = expensesList
              .firstWhere((e) => (e as Map<String, Object?>)['id'] == 'e2')
          as Map<String, Object?>;

      expect(exp1['receipt_image_uri'], uri1);
      expect(exp2['receipt_image_uri'], uri2);
    });

    test('verifies format_version matches expected constant 1', () {
      expect(WalletMeltJsonBackupEncoder.formatVersion, equals(1));
    });
  });
}

GroceryItem _groceryItem({
  String id = 'grocery_item_1',
  String expenseId = 'expense_1',
  String name = 'Milk',
  double amount = 520,
  String createdAt = '2026-06-14T10:00:00.000',
}) {
  return GroceryItem(
    id: id,
    expenseId: expenseId,
    name: name,
    amount: amount,
    createdAt: createdAt,
  );
}

CategoryBudget _budget({
  String id = 'budget_1',
  String categoryId = 'grocery',
  double amount = 30000,
  String currency = 'PKR',
  String month = '2026-06',
  String createdAt = '2026-06-01T00:00:00.000',
  String updatedAt = '2026-06-01T00:00:00.000',
}) {
  return CategoryBudget(
    id: id,
    categoryId: categoryId,
    amount: amount,
    currency: currency,
    month: month,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

Category _category({
  String id = 'grocery',
  String name = 'Groceries',
}) {
  return Category(
    id: id,
    name: name,
    icon: 'shopping_basket',
    color: '#000000',
    isDefault: true,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
  );
}

Expense _expense({
  String id = 'expense_1',
  double amount = 1200.5,
  String currency = 'PKR',
  String categoryId = 'grocery',
  String title = 'Grocery',
  String? vendor = 'Metro',
  String date = '2026-06-14T00:00:00.000',
  String? notes = 'Weekly shop',
  String? receiptImageUri = 'file:///receipt.jpg',
  bool isRecurring = false,
  RecurrenceFrequency? recurrenceFrequency,
  String createdAt = '2026-06-14T10:00:00.000',
  String updatedAt = '2026-06-14T10:00:00.000',
  String? deletedAt,
}) {
  return Expense(
    id: id,
    amount: amount,
    currency: currency,
    categoryId: categoryId,
    title: title,
    vendor: vendor,
    date: date,
    notes: notes,
    receiptImageUri: receiptImageUri,
    isRecurring: isRecurring,
    recurrenceFrequency: recurrenceFrequency,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

WalletMeltSettings _settings({String? lastExportedAt = '2026-06-13'}) {
  return WalletMeltSettings(
    currency: 'PKR',
    themePreference: ThemePreference.system,
    hasCompletedOnboarding: true,
    lastExportedAt: lastExportedAt,
  );
}
