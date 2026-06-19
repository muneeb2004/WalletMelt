import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_conflict_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_dry_run_planner.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_plan.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  group('WalletMeltJsonRestoreDryRunPlanner', () {
    const planner = WalletMeltJsonRestoreDryRunPlanner();

    test('clean backup against empty local data produces insert plan', () {
      final plan = planner.plan(
        jsonText: _backupJson(),
        localSnapshot: _snapshot(),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(plan.isValid, isTrue);
      expect(plan.hasBlockers, isFalse);
      expect(plan.plannedCounts.categories, 1);
      expect(plan.plannedCounts.expenses, 1);
      expect(plan.plannedCounts.groceryItems, 1);
      expect(plan.plannedCounts.budgets, 1);
      expect(
        plan.actions
            .where((action) => action.type == RestoreDryRunActionType.insert),
        hasLength(4),
      );
    });

    test('duplicate expense ID produces proposed remap', () {
      final plan = planner.plan(
        jsonText: _backupJson(),
        localSnapshot: _snapshot(expenses: [_expense(id: 'expense_1')]),
        conflictSummary: const BackupConflictSummary(),
      );

      final mapping = plan.idMappings.singleWhere(
        (mapping) =>
            mapping.entity == RestoreDryRunEntity.expense &&
            mapping.sourceId == 'expense_1',
      );

      expect(mapping.preservesSourceId, isFalse);
      expect(mapping.targetId, startsWith('restore_expense_expense_1'));
      expect(
        plan.idMappings
            .where(
                (mapping) => mapping.entity == RestoreDryRunEntity.groceryItem)
            .single
            .reason,
        'Grocery item ID is available.',
      );
      expect(plan.hasBlockers, isFalse);
    });

    test('duplicate-heavy backup is blocked before mutation eligibility', () {
      final plan = planner.plan(
        jsonText: _backupJson(
          categories: [
            _categoryJson(id: 'cat_1', name: 'Groceries'),
            _categoryJson(id: 'cat_1', name: 'Groceries duplicate'),
            _categoryJson(id: 'cat_2', name: 'Groceries'),
          ],
          expenses: [
            _expenseJson(id: 'expense_1'),
            _expenseJson(id: 'expense_1'),
          ],
          groceryItems: [
            _groceryItemJson(id: 'item_1'),
            _groceryItemJson(id: 'item_1'),
          ],
          budgets: [
            _budgetJson(id: 'budget_1'),
            _budgetJson(id: 'budget_1'),
            _budgetJson(id: 'budget_2'),
          ],
        ),
        localSnapshot: _snapshot(),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(plan.hasBlockers, isTrue);
      expect(plan.canStartFutureMutation, isFalse);
      expect(
        plan.issues.where((issue) => issue.message.contains('more than once')),
        isNotEmpty,
      );
      expect(
        plan.issues.where((issue) => issue.message.contains('Category name')),
        isNotEmpty,
      );
      expect(
        plan.issues.where(
            (issue) => issue.message.contains('Multiple backup budgets')),
        isNotEmpty,
      );
    });

    test('duplicate equivalent category ID maps to existing category', () {
      final plan = planner.plan(
        jsonText: _backupJson(),
        localSnapshot: _snapshot(categories: [_category(id: 'cat_1')]),
        conflictSummary: const BackupConflictSummary(),
      );

      final mapping = plan.idMappings.singleWhere(
        (mapping) => mapping.entity == RestoreDryRunEntity.category,
      );
      expect(mapping.targetId, 'cat_1');
      expect(mapping.preservesSourceId, isTrue);
      expect(plan.plannedCounts.categories, 0);
    });

    test('category name conflict is classified as blocker for custom category',
        () {
      final plan = planner.plan(
        jsonText: _backupJson(
          categories: [
            _categoryJson(
                id: 'backup_custom', name: 'Groceries', isDefault: false),
          ],
        ),
        localSnapshot: _snapshot(
          categories: [
            _category(id: 'local_custom', name: 'Groceries', isDefault: false)
          ],
        ),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(plan.hasBlockers, isTrue);
      expect(
        plan.issues
            .where((issue) => issue.entity == RestoreDryRunEntity.category),
        isNotEmpty,
      );
      expect(plan.plannedCounts.categories, 0);
    });

    test('default category name conflict maps with warning', () {
      final plan = planner.plan(
        jsonText: _backupJson(
          categories: [_categoryJson(id: 'backup_default', name: 'Groceries')],
          expenses: [_expenseJson(categoryId: 'backup_default')],
          budgets: [_budgetJson(categoryId: 'backup_default')],
        ),
        localSnapshot: _snapshot(categories: [_category(id: 'local_default')]),
        conflictSummary: const BackupConflictSummary(),
      );

      final mapping = plan.idMappings.singleWhere(
        (mapping) => mapping.entity == RestoreDryRunEntity.category,
      );
      expect(mapping.sourceId, 'backup_default');
      expect(mapping.targetId, 'local_default');
      expect(plan.warningCount, greaterThan(0));
      expect(plan.hasBlockers, isFalse);
    });

    test('grocery item references remapped expense ID', () {
      final plan = planner.plan(
        jsonText: _backupJson(),
        localSnapshot: _snapshot(expenses: [_expense(id: 'expense_1')]),
        conflictSummary: const BackupConflictSummary(),
      );

      final groceryAction = plan.actions.singleWhere(
        (action) => action.entity == RestoreDryRunEntity.groceryItem,
      );

      expect(
        groceryAction.description,
        contains('restore_expense_expense_1'),
      );
    });

    test('orphan grocery item becomes blocker', () {
      final plan = planner.plan(
        jsonText: _backupJson(
          groceryItems: [
            _groceryItemJson(id: 'item_orphan', expenseId: 'missing')
          ],
        ),
        localSnapshot: _snapshot(),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(plan.hasBlockers, isTrue);
      expect(
        plan.issues
            .singleWhere(
              (issue) => issue.entity == RestoreDryRunEntity.groceryItem,
            )
            .message,
        contains('cannot be resolved'),
      );
    });

    test('budget category references remapped category ID', () {
      final plan = planner.plan(
        jsonText: _backupJson(),
        localSnapshot: _snapshot(
          categories: [
            _category(id: 'cat_1', name: 'Different', isDefault: false),
          ],
        ),
        conflictSummary: const BackupConflictSummary(),
      );

      final budgetAction = plan.actions.singleWhere(
        (action) => action.entity == RestoreDryRunEntity.budget,
      );

      expect(budgetAction.description, contains('restore_category_cat_1'));
      expect(plan.warningCount, greaterThan(0));
      expect(plan.hasBlockers, isFalse);
    });

    test('budget month/category collision is detected as blocker', () {
      final plan = planner.plan(
        jsonText: _backupJson(),
        localSnapshot: _snapshot(
          categories: [_category(id: 'cat_1')],
          budgets: [_budget(id: 'local_budget', categoryId: 'cat_1')],
        ),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(plan.hasBlockers, isTrue);
      expect(
        plan.issues
            .singleWhere(
              (issue) => issue.entity == RestoreDryRunEntity.budget,
            )
            .message,
        contains('collides with existing month + category'),
      );
    });

    test('settings import is optional by default', () {
      final plan = planner.plan(
        jsonText: _backupJson(),
        localSnapshot: _snapshot(),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(plan.plannedCounts.settings, 0);
      expect(plan.restorePlan.importsSettings, isFalse);
      expect(
        plan.issues
            .any((issue) => issue.entity == RestoreDryRunEntity.settings),
        isTrue,
      );
    });

    test('settings import can be selected without mutating state', () {
      final plan = planner.plan(
        jsonText: _backupJson(settings: {'currency': 'USD'}),
        localSnapshot: _snapshot(),
        conflictSummary: const BackupConflictSummary(),
        settingsImportSelected: true,
      );

      expect(plan.plannedCounts.settings, 1);
      expect(plan.restorePlan.importsSettings, isTrue);
      expect(plan.warningCount, greaterThan(0));
    });

    test('receipt URI/path warning is retained', () {
      final plan = planner.plan(
        jsonText: _backupJson(
          expenses: [_expenseJson(receiptImageUri: 'file:///missing.jpg')],
        ),
        localSnapshot: _snapshot(),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(
        plan.issues.any(
          (issue) => issue.entity == RestoreDryRunEntity.receiptReference,
        ),
        isTrue,
      );
    });

    test('unsupported or invalid backup is rejected at planner boundary', () {
      final plan = planner.plan(
        jsonText: _backupJson(formatVersion: 99),
        localSnapshot: _snapshot(),
      );

      expect(plan.isValid, isFalse);
      expect(plan.hasBlockers, isTrue);
      expect(plan.error, contains('Unsupported format version'));
    });

    test('blockers prevent future mutation eligibility', () {
      final plan = planner.plan(
        jsonText: _backupJson(
          groceryItems: [
            _groceryItemJson(id: 'item_orphan', expenseId: 'missing')
          ],
        ),
        localSnapshot: _snapshot(),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(plan.hasBlockers, isTrue);
      expect(plan.canStartFutureMutation, isFalse);
      expect(
        plan.safetyGates
            .singleWhere(
              (gate) =>
                  gate.gate == RestoreDryRunSafetyGate.noUnresolvedBlockers,
            )
            .satisfied,
        isFalse,
      );
    });

    test('ordered future transaction steps match restore design', () {
      final plan = planner.plan(
        jsonText: _backupJson(),
        localSnapshot: _snapshot(),
        conflictSummary: const BackupConflictSummary(),
      );

      expect(plan.futureExecutionSteps, RestorePlan.mutationPlanningSteps);
      expect(
          plan.futureExecutionSteps.first, RestoreExecutionStep.validateFormat);
      expect(
          plan.futureExecutionSteps.last, RestoreExecutionStep.refreshAppState);
    });
  });
}

String _backupJson({
  int formatVersion = 1,
  List<Map<String, Object?>>? categories,
  List<Map<String, Object?>>? expenses,
  List<Map<String, Object?>>? groceryItems,
  List<Map<String, Object?>>? budgets,
  Map<String, Object?>? settings,
}) {
  return const JsonEncoder().convert({
    'metadata': {
      'format': 'walletmelt.local_json_backup',
      'format_version': formatVersion,
      'app_version': '0.1.1+2',
      'exported_at': '2026-06-14T09:08:07.000',
      'includes': [
        'expenses',
        'grocery_items',
        'categories',
        'budgets',
        'settings'
      ],
    },
    'categories': categories ?? [_categoryJson()],
    'expenses': expenses ?? [_expenseJson()],
    'grocery_items': groceryItems ?? [_groceryItemJson()],
    'budgets': budgets ?? [_budgetJson()],
    'settings': settings ??
        {
          'currency': 'PKR',
          'theme_preference': 'system',
          'has_completed_onboarding': true,
          'last_exported_at': null,
        },
  });
}

Map<String, Object?> _categoryJson({
  String id = 'cat_1',
  String name = 'Groceries',
  bool isDefault = true,
}) {
  return {
    'id': id,
    'name': name,
    'icon': 'shopping_basket',
    'color': '#000000',
    'is_default': isDefault,
    'created_at': '2026-06-14T00:00:00.000',
    'updated_at': '2026-06-14T00:00:00.000',
  };
}

Map<String, Object?> _expenseJson({
  String id = 'expense_1',
  String categoryId = 'cat_1',
  String? receiptImageUri,
}) {
  return {
    'id': id,
    'amount': 1200,
    'currency': 'PKR',
    'category_id': categoryId,
    'title': 'Weekly grocery',
    'vendor': null,
    'date': '2026-06-14T00:00:00.000',
    'notes': null,
    'receipt_image_uri': receiptImageUri,
    'is_recurring': false,
    'recurrence_frequency': null,
    'created_at': '2026-06-14T10:00:00.000',
    'updated_at': '2026-06-14T10:00:00.000',
    'deleted_at': null,
  };
}

Map<String, Object?> _groceryItemJson({
  String id = 'item_1',
  String expenseId = 'expense_1',
}) {
  return {
    'id': id,
    'expense_id': expenseId,
    'name': 'Milk',
    'amount': 520,
    'created_at': '2026-06-14T10:00:00.000',
  };
}

Map<String, Object?> _budgetJson({
  String id = 'budget_1',
  String categoryId = 'cat_1',
}) {
  return {
    'id': id,
    'category_id': categoryId,
    'amount': 30000,
    'currency': 'PKR',
    'month': '2026-06',
    'created_at': '2026-06-01T00:00:00.000',
    'updated_at': '2026-06-01T00:00:00.000',
  };
}

LocalAppSnapshot _snapshot({
  List<Expense> expenses = const [],
  List<Expense> deletedExpenses = const [],
  List<Category> categories = const [],
  List<CategoryBudget> budgets = const [],
  List<GroceryItem> groceryItems = const [],
  WalletMeltSettings? settings,
}) {
  return LocalAppSnapshot(
    expenses: expenses,
    deletedExpenses: deletedExpenses,
    categories: categories,
    budgets: budgets,
    groceryItems: groceryItems,
    settings: settings ??
        WalletMeltSettings.defaults.copyWith(hasCompletedOnboarding: true),
  );
}

Category _category({
  required String id,
  String name = 'Groceries',
  bool isDefault = true,
}) {
  return Category(
    id: id,
    name: name,
    icon: 'shopping_basket',
    color: '#000000',
    isDefault: isDefault,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
  );
}

Expense _expense({required String id}) {
  return Expense(
    id: id,
    amount: 1200,
    currency: 'PKR',
    categoryId: 'cat_1',
    title: 'Weekly grocery',
    date: '2026-06-14T00:00:00.000',
    isRecurring: false,
    createdAt: '2026-06-14T10:00:00.000',
    updatedAt: '2026-06-14T10:00:00.000',
  );
}

CategoryBudget _budget({
  required String id,
  required String categoryId,
}) {
  return CategoryBudget(
    id: id,
    categoryId: categoryId,
    amount: 30000,
    currency: 'PKR',
    month: '2026-06',
    createdAt: '2026-06-01T00:00:00.000',
    updatedAt: '2026-06-01T00:00:00.000',
  );
}
