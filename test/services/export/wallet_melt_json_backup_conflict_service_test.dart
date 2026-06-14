import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_conflict_service.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/settings.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _service = WalletMeltJsonBackupConflictService();

/// Sentinel object used as a default parameter marker for the [settings]
/// parameter in [_buildBackupJson]. This allows callers to explicitly pass
/// `null` to test the "no settings block" case while still defaulting to a
/// valid settings map when not specified.
const Object _kDefaultSettings = Object();

LocalAppSnapshot _emptySnapshot() => LocalAppSnapshot(
      expenses: const [],
      deletedExpenses: const [],
      categories: const [],
      budgets: const [],
      groceryItems: const [],
      settings: WalletMeltSettings.defaults,
    );

String _buildBackupJson({
  List<Map<String, Object?>> expenses = const [],
  List<Map<String, Object?>> groceryItems = const [],
  List<Map<String, Object?>> categories = const [],
  List<Map<String, Object?>> budgets = const [],
  Object? settings = _kDefaultSettings,
  String? appVersion = '1.0.0',
}) {
  return jsonEncode({
    'metadata': {
      'format': 'walletmelt.local_json_backup',
      'format_version': 1,
      'app_version': appVersion,
      'exported_at': '2026-06-14T09:08:07.000',
      'includes': ['expenses', 'grocery_items', 'categories', 'budgets', 'settings'],
    },
    'expenses': expenses,
    'grocery_items': groceryItems,
    'categories': categories,
    'budgets': budgets,
    'settings': settings == _kDefaultSettings
        ? {
            'currency': WalletMeltSettings.defaults.currency,
            'theme_preference':
                WalletMeltSettings.defaults.themePreference.name,
            'has_completed_onboarding':
                WalletMeltSettings.defaults.hasCompletedOnboarding,
            'last_exported_at': null,
          }
        : settings,
  });
}

Expense _expense({
  required String id,
  String? deletedAt,
}) {
  return Expense(
    id: id,
    amount: 100,
    currency: 'PKR',
    categoryId: 'cat1',
    title: 'Test Expense',
    date: '2026-06-14',
    isRecurring: false,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
    deletedAt: deletedAt,
  );
}

Category _category({required String id, String name = 'Food'}) {
  return Category(
    id: id,
    name: name,
    icon: 'food',
    color: '#FF0000',
    isDefault: false,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
  );
}

CategoryBudget _budget({
  required String id,
  required String categoryId,
  required String month,
}) {
  return CategoryBudget(
    id: id,
    categoryId: categoryId,
    amount: 5000,
    currency: 'PKR',
    month: month,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
  );
}

GroceryItem _groceryItem({required String id, required String expenseId}) {
  return GroceryItem(
    id: id,
    expenseId: expenseId,
    name: 'Item',
    amount: 50,
    createdAt: '2026-06-14T00:00:00.000',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('WalletMeltJsonBackupConflictService — clean baseline', () {
    test('returns no conflicts for empty local data and empty backup', () {
      final json = _buildBackupJson();
      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.hasAnyConflict, isFalse);
      expect(result.duplicateExpenseIdCount, 0);
      expect(result.duplicateCategoryIdCount, 0);
      expect(result.duplicateBudgetMonthCategoryCount, 0);
      expect(result.groceryOrphanCount, 0);
      expect(result.receiptReferenceCount, 0);
      expect(result.summaryLines, isEmpty);
    });

    test('returns no conflicts when backup IDs do not match local data', () {
      final json = _buildBackupJson(
        expenses: [
          {'id': 'exp-backup', 'deleted_at': null, 'receipt_image_uri': null},
        ],
        categories: [
          {'id': 'cat-backup', 'name': 'Travel'},
        ],
        budgets: [
          {'id': 'bud-backup', 'category_id': 'cat-backup', 'month': '2026-07'},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [_expense(id: 'exp-local')],
        deletedExpenses: [],
        categories: [_category(id: 'cat-local', name: 'Food')],
        budgets: [_budget(id: 'bud-local', categoryId: 'cat-local', month: '2026-06')],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.duplicateExpenseIdCount, 0);
      expect(result.duplicateCategoryIdCount, 0);
      expect(result.duplicateBudgetMonthCategoryCount, 0);
    });
  });

  group('WalletMeltJsonBackupConflictService — expense conflicts', () {
    test('detects duplicate expense IDs present locally (active)', () {
      final json = _buildBackupJson(
        expenses: [
          {'id': 'exp1', 'deleted_at': null, 'receipt_image_uri': null},
          {'id': 'exp2', 'deleted_at': null, 'receipt_image_uri': null},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [_expense(id: 'exp1')],
        deletedExpenses: [],
        categories: [],
        budgets: [],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.duplicateExpenseIdCount, 1);
      expect(result.hasAnyConflict, isTrue);
    });

    test('detects duplicate expense ID present in local deleted expenses', () {
      final json = _buildBackupJson(
        expenses: [
          {'id': 'del-exp', 'deleted_at': null, 'receipt_image_uri': null},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [
          _expense(id: 'del-exp', deletedAt: '2026-06-15T00:00:00.000'),
        ],
        categories: [],
        budgets: [],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.duplicateExpenseIdCount, 1);
    });

    test('counts soft-deleted backup expenses', () {
      final json = _buildBackupJson(
        expenses: [
          {'id': 'exp1', 'deleted_at': '2026-06-15T00:00:00.000', 'receipt_image_uri': null},
          {'id': 'exp2', 'deleted_at': null, 'receipt_image_uri': null},
        ],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.softDeletedBackupExpenseCount, 1);
    });

    test('detects backup expenses with receipt URI references', () {
      final json = _buildBackupJson(
        expenses: [
          {
            'id': 'exp1',
            'deleted_at': null,
            'receipt_image_uri': 'file:///path/to/receipt.jpg',
          },
          {'id': 'exp2', 'deleted_at': null, 'receipt_image_uri': null},
        ],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.receiptReferenceCount, 1);
      expect(result.hasAnyConflict, isTrue);
      expect(
        result.summaryLines.any((l) => l.contains('receipt image path')),
        isTrue,
      );
    });
  });

  group('WalletMeltJsonBackupConflictService — category conflicts', () {
    test('detects duplicate category IDs already present locally', () {
      final json = _buildBackupJson(
        categories: [
          {'id': 'cat1', 'name': 'Food'},
          {'id': 'cat2', 'name': 'Transport'},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [],
        categories: [_category(id: 'cat1', name: 'Food')],
        budgets: [],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.duplicateCategoryIdCount, 1);
      expect(result.hasAnyConflict, isTrue);
    });

    test('detects same category name with different ID (name/ID mismatch)', () {
      final json = _buildBackupJson(
        categories: [
          {'id': 'cat-new', 'name': 'Food'},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [],
        categories: [_category(id: 'cat-local', name: 'Food')],
        budgets: [],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.categoryNameIdMismatchCount, 1);
      expect(result.hasAnyConflict, isTrue);
    });

    test('detects same category ID with different name (name/ID mismatch)', () {
      final json = _buildBackupJson(
        categories: [
          {'id': 'cat1', 'name': 'New Name'},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [],
        categories: [_category(id: 'cat1', name: 'Old Name')],
        budgets: [],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      // Both duplicateId and nameIdMismatch should fire.
      expect(result.duplicateCategoryIdCount, 1);
      expect(result.categoryNameIdMismatchCount, 1);
    });

    test('case-insensitive name match counts as name/ID mismatch', () {
      final json = _buildBackupJson(
        categories: [
          {'id': 'cat-new', 'name': 'FOOD'},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [],
        categories: [_category(id: 'cat-local', name: 'food')],
        budgets: [],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.categoryNameIdMismatchCount, 1);
    });
  });

  group('WalletMeltJsonBackupConflictService — budget conflicts', () {
    test('detects same month + category_id budget already existing locally', () {
      final json = _buildBackupJson(
        categories: [
          {'id': 'cat1', 'name': 'Food'},
        ],
        budgets: [
          {'id': 'bud-backup', 'category_id': 'cat1', 'month': '2026-06'},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [],
        categories: [],
        budgets: [_budget(id: 'bud-local', categoryId: 'cat1', month: '2026-06')],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.duplicateBudgetMonthCategoryCount, 1);
      expect(result.hasAnyConflict, isTrue);
    });

    test('no budget conflict when month or category differs', () {
      final json = _buildBackupJson(
        categories: [
          {'id': 'cat1', 'name': 'Food'},
        ],
        budgets: [
          {'id': 'bud-backup', 'category_id': 'cat1', 'month': '2026-07'},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [],
        categories: [],
        budgets: [_budget(id: 'bud-local', categoryId: 'cat1', month: '2026-06')],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.duplicateBudgetMonthCategoryCount, 0);
    });

    test('detects budget referencing a category_id missing from backup', () {
      final json = _buildBackupJson(
        categories: [], // no categories in backup
        budgets: [
          {'id': 'bud1', 'category_id': 'cat-missing', 'month': '2026-06'},
        ],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.budgetMissingCategoryCount, 1);
      expect(result.hasAnyConflict, isTrue);
    });
  });

  group('WalletMeltJsonBackupConflictService — grocery item conflicts', () {
    test('detects orphan grocery item referencing missing backup expense_id', () {
      final json = _buildBackupJson(
        expenses: [],
        groceryItems: [
          {
            'id': 'item1',
            'expense_id': 'exp-ghost',
            'name': 'Milk',
            'amount': 50,
          },
        ],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.groceryOrphanCount, 1);
      expect(result.hasAnyConflict, isTrue);
    });

    test('does not flag grocery item whose expense_id is in backup expenses', () {
      final json = _buildBackupJson(
        expenses: [
          {'id': 'exp1', 'deleted_at': null, 'receipt_image_uri': null},
        ],
        groceryItems: [
          {
            'id': 'item1',
            'expense_id': 'exp1',
            'name': 'Bread',
            'amount': 30,
          },
        ],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.groceryOrphanCount, 0);
    });

    test('does not flag grocery item whose expense_id is in local data', () {
      final json = _buildBackupJson(
        expenses: [],
        groceryItems: [
          {
            'id': 'item1',
            'expense_id': 'exp-local',
            'name': 'Tea',
            'amount': 20,
          },
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [_expense(id: 'exp-local')],
        deletedExpenses: [],
        categories: [],
        budgets: [],
        groceryItems: [_groceryItem(id: 'item1', expenseId: 'exp-local')],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.groceryOrphanCount, 0);
    });
  });

  group('WalletMeltJsonBackupConflictService — metadata / settings warnings', () {
    test('warns when app_version is null', () {
      final json = _buildBackupJson(appVersion: null);

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.appVersionWarning, isNotNull);
      expect(result.hasAnyConflict, isTrue);
    });

    test('warns when app_version is empty string', () {
      final json = _buildBackupJson(appVersion: '');

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.appVersionWarning, isNotNull);
    });

    test('no app_version warning when app_version is present', () {
      final json = _buildBackupJson(appVersion: '1.2.3');

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.appVersionWarning, isNull);
    });

    test('warns when backup settings are missing (null)', () {
      final json = _buildBackupJson(settings: null);

      final result = _service.detect(
        jsonText: json,
        localSnapshot: const LocalAppSnapshot(
          expenses: [],
          deletedExpenses: [],
          categories: [],
          budgets: [],
          groceryItems: [],
          settings: null,
        ),
      );

      expect(result.settingsWarning, isNotNull);
      expect(
        result.settingsWarning!.contains('does not include a settings block'),
        isTrue,
      );
    });

    test('warns when backup settings currency differs from current settings', () {
      final json = _buildBackupJson(
        settings: {
          'currency': 'USD',
          'theme_preference': 'system',
          'has_completed_onboarding': true,
          'last_exported_at': null,
        },
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [],
        categories: [],
        budgets: [],
        groceryItems: [],
        settings: WalletMeltSettings.defaults.copyWith(currency: 'PKR'),
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.settingsWarning, isNotNull);
      expect(result.settingsWarning!.contains('currency'), isTrue);
    });

    test('no settings warning when backup settings match current settings', () {
      // WalletMeltSettings.defaults has currency 'USD' but let us match it.
      final defaults = WalletMeltSettings.defaults;
      final json2 = _buildBackupJson(
        settings: {
          'currency': defaults.currency,
          'theme_preference': defaults.themePreference.name,
          'has_completed_onboarding': defaults.hasCompletedOnboarding,
          'last_exported_at': null,
        },
      );
      final snapshot = LocalAppSnapshot(
        expenses: [],
        deletedExpenses: [],
        categories: [],
        budgets: [],
        groceryItems: [],
        settings: defaults,
      );

      final result = _service.detect(
        jsonText: json2,
        localSnapshot: snapshot,
      );

      expect(result.settingsWarning, isNull);
    });
  });

  group('WalletMeltJsonBackupConflictService — summaryLines', () {
    test('summaryLines is empty when no conflicts', () {
      final json = _buildBackupJson();

      final result = _service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );

      expect(result.summaryLines, isEmpty);
    });

    test('summaryLines includes lines for all detected conflict types', () {
      final json = _buildBackupJson(
        appVersion: null,
        expenses: [
          {
            'id': 'exp-dup',
            'deleted_at': '2026-06-15',
            'receipt_image_uri': 'file:///img.jpg',
          },
        ],
        groceryItems: [
          {'id': 'item-orphan', 'expense_id': 'ghost-id', 'name': 'X', 'amount': 1},
        ],
        categories: [
          {'id': 'cat-dup', 'name': 'Food'},
        ],
        budgets: [
          {'id': 'bud-dup', 'category_id': 'cat-dup', 'month': '2026-06'},
        ],
      );
      final snapshot = LocalAppSnapshot(
        expenses: [_expense(id: 'exp-dup')],
        deletedExpenses: [],
        categories: [_category(id: 'cat-dup', name: 'Food')],
        budgets: [_budget(id: 'bud-local', categoryId: 'cat-dup', month: '2026-06')],
        groceryItems: [],
      );

      final result = _service.detect(
        jsonText: json,
        localSnapshot: snapshot,
      );

      expect(result.summaryLines.length, greaterThan(1));
    });
  });

  group('WalletMeltJsonBackupConflictService — no mutation', () {
    test('service does not expose any write or mutation methods', () {
      // Verify the service class only exposes the detect() method.
      // This test documents the read-only contract.
      const service = WalletMeltJsonBackupConflictService();
      // detect() returns a plain data object — no side effects.
      final json = _buildBackupJson();
      final result = service.detect(
        jsonText: json,
        localSnapshot: _emptySnapshot(),
      );
      expect(result, isA<BackupConflictSummary>());
    });

    test('returns gracefully for malformed JSON input', () {
      final result = _service.detect(
        jsonText: '{ not valid json }',
        localSnapshot: _emptySnapshot(),
      );
      // Must not throw; hasAnyConflict is set to true as a safe default.
      expect(result, isA<BackupConflictSummary>());
      expect(result.hasAnyConflict, isTrue);
    });
  });
}
