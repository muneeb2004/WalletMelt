import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' as local;
import 'package:wallet_melt/src/services/export/export_file_writer.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_conflict_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_dry_run_planner.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_plan.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_service.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart' as domain;
import 'package:wallet_melt/src/types/expense.dart' as domain;
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/settings.dart';

void main() {
  group('WalletMeltJsonRestoreService', () {
    test('fails if confirmation is missing', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);

      final result = await harness.service.restoreSafeMerge(
        jsonText: _backupJson(),
        dryRunPlan: harness.plan(_backupJson()),
        options: const WalletMeltJsonRestoreOptions(),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('explicit confirmation'));
      expect(await harness.expenseCount(), 0);
    });

    test('fails if safety backup is missing', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);

      final result = await harness.service.restoreSafeMerge(
        jsonText: _backupJson(),
        dryRunPlan: harness.plan(_backupJson()),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: ExportFileResult(
          path: '${harness.tempDir.path}/missing.json',
          fileName: 'missing.json',
          mimeType: ExportFileWriter.jsonMimeType,
          byteCount: 0,
          createdAt: DateTime(2026, 6, 14),
        ),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('safety backup'));
      expect(await harness.expenseCount(), 0);
    });

    test('fails if dry-run has blockers', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      final json = _backupJson(
        groceryItems: [_groceryItemJson(expenseId: 'missing')],
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: harness.plan(json),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('dry-run issues'));
      expect(await harness.expenseCount(), 0);
    });

    test('invalid backup cannot trigger restore', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);

      final result = await harness.service.restoreSafeMerge(
        jsonText: '{"metadata":',
        dryRunPlan: harness.plan(_backupJson()),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Malformed JSON'));
      expect(await harness.expenseCount(), 0);
    });

    test('duplicate-heavy backup is rejected at service preflight', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      final duplicateJson = _backupJson(
        categories: [
          _categoryJson(id: 'restore_cat_1', name: 'Backup Supplies'),
          _categoryJson(id: 'restore_cat_1', name: 'Backup Supplies Copy'),
          _categoryJson(id: 'restore_cat_2', name: 'Backup Supplies'),
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
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: duplicateJson,
        dryRunPlan: harness.plan(_backupJson()),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Backup cannot be restored safely'));
      expect(result.errorMessage, contains('Duplicate expense ID'));
      expect(await harness.expenseCount(), 0);
    });

    test('safe merge inserts into empty local data', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      final json = _backupJson();

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: harness.plan(json),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isTrue);
      expect(result.insertedCategories, 1);
      expect(result.insertedExpenses, 1);
      expect(result.insertedGroceryItems, 1);
      expect(result.insertedBudgets, 1);
      expect(await harness.categoryExists('restore_cat_1'), isTrue);
      expect(await harness.expenseExists('expense_1'), isTrue);
      expect(await harness.groceryItemExists('item_1'), isTrue);
      expect(await harness.budgetExists('budget_1'), isTrue);
    });

    test('duplicate expense ID is remapped and local expense preserved',
        () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      await harness.insertCategory(id: 'restore_cat_1');
      await harness.insertExpense(id: 'expense_1', categoryId: 'restore_cat_1');
      final json = _backupJson(
        categories: [_categoryJson(id: 'restore_cat_1')],
      );
      final plan = harness.plan(
        json,
        expenses: [_expense(id: 'expense_1', categoryId: 'restore_cat_1')],
        categories: [_category(id: 'restore_cat_1')],
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: plan,
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      final remap = plan.idMappings.singleWhere(
        (mapping) => mapping.entity == RestoreDryRunEntity.expense,
      );
      expect(result.success, isTrue);
      expect(remap.preservesSourceId, isFalse);
      expect(await harness.expenseExists('expense_1'), isTrue);
      expect(await harness.expenseExists(remap.targetId), isTrue);
      expect(await harness.expenseCount(), 2);
    });

    test('category mapping is applied to expenses', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      await harness.insertCategory(id: 'local_grocery', name: 'Grocery');
      final json = _backupJson(
        categories: [
          _categoryJson(
            id: 'backup_grocery',
            name: 'Grocery',
            isDefault: true,
          )
        ],
        expenses: [_expenseJson(categoryId: 'backup_grocery')],
        budgets: const [],
      );
      final plan = harness.plan(
        json,
        categories: [
          _category(id: 'local_grocery', name: 'Grocery', isDefault: true)
        ],
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: plan,
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      final expense = await harness.expense('expense_1');
      expect(result.success, isTrue);
      expect(expense?.categoryId, 'local_grocery');
    });

    test('grocery item parent reference is remapped', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      await harness.insertCategory(id: 'restore_cat_1');
      await harness.insertExpense(id: 'expense_1', categoryId: 'restore_cat_1');
      final json =
          _backupJson(categories: [_categoryJson(id: 'restore_cat_1')]);
      final plan = harness.plan(
        json,
        expenses: [_expense(id: 'expense_1', categoryId: 'restore_cat_1')],
        categories: [_category(id: 'restore_cat_1')],
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: plan,
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      final expenseRemap = plan.idMappings.singleWhere(
        (mapping) => mapping.entity == RestoreDryRunEntity.expense,
      );
      final item = await harness.groceryItem('item_1');
      expect(result.success, isTrue);
      expect(item?.expenseId, expenseRemap.targetId);
    });

    test('soft-deleted expense import remains soft-deleted', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      final json = _backupJson(
        expenses: [
          _expenseJson(deletedAt: '2026-06-14T12:00:00.000'),
        ],
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: harness.plan(json),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      final expense = await harness.expense('expense_1');
      expect(result.success, isTrue);
      expect(expense?.deletedAt, '2026-06-14T12:00:00.000');
    });

    test('orphan grocery item blocks restore', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      final json = _backupJson(
        groceryItems: [_groceryItemJson(expenseId: 'missing_expense')],
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: harness.plan(json),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isFalse);
      expect(await harness.groceryItemCount(), 0);
    });

    test('budget conflict does not overwrite local budget', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      await harness.insertCategory(id: 'restore_cat_1');
      await harness.insertBudget(
        id: 'local_budget',
        categoryId: 'restore_cat_1',
        amount: 9000,
      );
      final json =
          _backupJson(categories: [_categoryJson(id: 'restore_cat_1')]);
      final plan = harness.plan(
        json,
        categories: [_category(id: 'restore_cat_1')],
        budgets: [_budget(id: 'local_budget', categoryId: 'restore_cat_1')],
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: plan,
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isFalse);
      expect(await harness.budgetAmount('local_budget'), 9000);
      expect(await harness.budgetCount(), 1);
    });

    test('settings are not imported by default', () async {
      final settingsService = _FakeSettingsService();
      final harness = await _RestoreHarness.create(
        settingsService: settingsService,
      );
      addTearDown(harness.dispose);

      final result = await harness.service.restoreSafeMerge(
        jsonText: _backupJson(settings: {'currency': 'USD'}),
        dryRunPlan: harness.plan(_backupJson(settings: {'currency': 'USD'})),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isTrue);
      expect(result.settingsImported, isFalse);
      expect(settingsService.saved, isNull);
    });

    test('settings import only occurs when option enabled', () async {
      final settingsService = _FakeSettingsService();
      final harness = await _RestoreHarness.create(
        settingsService: settingsService,
      );
      addTearDown(harness.dispose);
      final json = _backupJson(settings: {'currency': 'USD'});

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: harness.plan(json, settingsImportSelected: true),
        options: const WalletMeltJsonRestoreOptions(
          confirmed: true,
          importSettings: true,
        ),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isTrue);
      expect(result.settingsImported, isTrue);
      expect(settingsService.saved?.currency, 'USD');
    });

    test('receipt URI/path text is preserved', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);
      final json = _backupJson(
        expenses: [_expenseJson(receiptImageUri: 'file:///missing.jpg')],
      );

      final result = await harness.service.restoreSafeMerge(
        jsonText: json,
        dryRunPlan: harness.plan(json),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      final expense = await harness.expense('expense_1');
      final receipts = await (harness.db.select(harness.db.receipts)
            ..where((receipt) => receipt.expenseId.equals('expense_1')))
          .get();
      expect(result.success, isTrue);
      expect(expense?.receiptImageUri, 'file:///missing.jpg');
      expect(receipts.single.uri, 'file:///missing.jpg');
      expect(result.warnings.single, contains('text only'));
    });

    test('rollback occurs on simulated write failure', () async {
      final harness = await _RestoreHarness.create(
        debugOnStep: (step) async {
          if (step == RestoreExecutionStep.importOrRemapExpenses) {
            throw StateError('simulated failure');
          }
        },
      );
      addTearDown(harness.dispose);

      final result = await harness.service.restoreSafeMerge(
        jsonText: _backupJson(),
        dryRunPlan: harness.plan(_backupJson()),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isFalse);
      expect(await harness.categoryExists('restore_cat_1'), isFalse);
      expect(await harness.expenseCount(), 0);
    });

    test('relationship verification failure rolls back transaction', () async {
      late _RestoreHarness harness;
      harness = await _RestoreHarness.create(
        debugOnStep: (step) async {
          if (step == RestoreExecutionStep.verifyCounts) {
            await harness.db.customStatement(
              'DELETE FROM expense_items WHERE expenseId = ?;',
              ['expense_1'],
            );
            await harness.db.customStatement(
              'DELETE FROM grocery_items WHERE expenseId = ?;',
              ['expense_1'],
            );
            await harness.db.customStatement(
              'DELETE FROM category_budgets WHERE categoryId = ?;',
              ['restore_cat_1'],
            );
            await harness.db.customStatement(
              'DELETE FROM expenses WHERE id = ?;',
              ['expense_1'],
            );
            await harness.db.customStatement(
              'DELETE FROM categories WHERE id = ?;',
              ['restore_cat_1'],
            );
          }
        },
      );
      addTearDown(harness.dispose);

      final result = await harness.service.restoreSafeMerge(
        jsonText: _backupJson(),
        dryRunPlan: harness.plan(_backupJson()),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('unresolved category'));
      expect(await harness.expenseCount(), 0);
      expect(await harness.categoryExists('restore_cat_1'), isFalse);
    });

    test('structured result reports inserted and skipped counts', () async {
      final harness = await _RestoreHarness.create();
      addTearDown(harness.dispose);

      final result = await harness.service.restoreSafeMerge(
        jsonText: _backupJson(),
        dryRunPlan: harness.plan(_backupJson()),
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
        safetyBackup: await harness.safetyBackup(),
      );

      expect(result.success, isTrue);
      expect(result.insertedCategories, 1);
      expect(result.insertedExpenses, 1);
      expect(result.insertedGroceryItems, 1);
      expect(result.insertedBudgets, 1);
      expect(result.skippedItems, 0);
      expect(result.safetyBackupPath, isNotNull);
    });
  });
}

class _RestoreHarness {
  _RestoreHarness._({
    required this.db,
    required this.tempDir,
    required this.service,
  });

  final local.WalletMeltDatabase db;
  final Directory tempDir;
  final WalletMeltJsonRestoreService service;
  final WalletMeltJsonRestoreDryRunPlanner planner =
      const WalletMeltJsonRestoreDryRunPlanner();

  static Future<_RestoreHarness> create({
    SettingsService? settingsService,
    Future<void> Function(RestoreExecutionStep step)? debugOnStep,
  }) async {
    final db = local.WalletMeltDatabase(NativeDatabase.memory());
    final tempDir =
        await Directory.systemTemp.createTemp('walletmelt_restore_');
    return _RestoreHarness._(
      db: db,
      tempDir: tempDir,
      service: WalletMeltJsonRestoreService(
        database: db,
        settingsService: settingsService,
        debugOnStep: debugOnStep,
      ),
    );
  }

  Future<void> dispose() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }

  RestoreDryRunPlan plan(
    String json, {
    List<domain.Expense> expenses = const [],
    List<domain.Expense> deletedExpenses = const [],
    List<domain.Category> categories = const [],
    List<CategoryBudget> budgets = const [],
    List<GroceryItem> groceryItems = const [],
    bool settingsImportSelected = false,
  }) {
    return planner.plan(
      jsonText: json,
      localSnapshot: LocalAppSnapshot(
        expenses: expenses,
        deletedExpenses: deletedExpenses,
        categories: categories,
        budgets: budgets,
        groceryItems: groceryItems,
        settings: WalletMeltSettings.defaults.copyWith(
          hasCompletedOnboarding: true,
        ),
      ),
      conflictSummary: const BackupConflictSummary(),
      settingsImportSelected: settingsImportSelected,
    );
  }

  Future<ExportFileResult> safetyBackup() async {
    final file = File('${tempDir.path}/safety.json');
    const content = '{"safety":true}';
    await file.writeAsString(content);
    return ExportFileResult(
      path: file.path,
      fileName: 'safety.json',
      mimeType: ExportFileWriter.jsonMimeType,
      byteCount: content.length,
      createdAt: DateTime(2026, 6, 14),
    );
  }

  Future<void> insertCategory({
    required String id,
    String name = 'Backup Supplies',
  }) {
    return db.into(db.categories).insert(
          local.CategoriesCompanion.insert(
            id: id,
            name: name,
            icon: 'shopping_basket',
            color: '#123456',
            isDefault: false,
            createdAt: '2026-06-01T00:00:00.000',
            updatedAt: '2026-06-01T00:00:00.000',
          ),
        );
  }

  Future<void> insertExpense({
    required String id,
    required String categoryId,
  }) {
    return db.into(db.expenses).insert(
          local.ExpensesCompanion.insert(
            id: id,
            amount: 400,
            currency: 'PKR',
            categoryId: categoryId,
            title: 'Existing',
            date: '2026-06-14T00:00:00.000',
            isRecurring: const Value(false),
            createdAt: '2026-06-14T08:00:00.000',
            updatedAt: '2026-06-14T08:00:00.000',
          ),
        );
  }

  Future<void> insertBudget({
    required String id,
    required String categoryId,
    required double amount,
  }) {
    return db.into(db.categoryBudgets).insert(
          local.CategoryBudgetsCompanion.insert(
            id: id,
            categoryId: categoryId,
            amount: amount,
            currency: 'PKR',
            month: '2026-06',
            createdAt: '2026-06-01T00:00:00.000',
            updatedAt: '2026-06-01T00:00:00.000',
          ),
        );
  }

  Future<bool> categoryExists(String id) async {
    final row = await (db.select(db.categories)
          ..where((category) => category.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<bool> expenseExists(String id) async => expense(id).then(
        (value) => value != null,
      );

  Future<local.Expense?> expense(String id) {
    return (db.select(db.expenses)..where((expense) => expense.id.equals(id)))
        .getSingleOrNull();
  }

  Future<bool> groceryItemExists(String id) async => groceryItem(id).then(
        (value) => value != null,
      );

  Future<local.GroceryItem?> groceryItem(String id) {
    return (db.select(db.groceryItems)..where((item) => item.id.equals(id)))
        .getSingleOrNull();
  }

  Future<bool> budgetExists(String id) async {
    final row = await (db.select(db.categoryBudgets)
          ..where((budget) => budget.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<double?> budgetAmount(String id) async {
    final row = await (db.select(db.categoryBudgets)
          ..where((budget) => budget.id.equals(id)))
        .getSingleOrNull();
    return row?.amount;
  }

  Future<int> expenseCount() async {
    final rows = await db.select(db.expenses).get();
    return rows.length;
  }

  Future<int> groceryItemCount() async {
    final rows = await db.select(db.groceryItems).get();
    return rows.length;
  }

  Future<int> budgetCount() async {
    final rows = await db.select(db.categoryBudgets).get();
    return rows.length;
  }
}

class _FakeSettingsService extends SettingsService {
  WalletMeltSettings? saved;

  @override
  Future<WalletMeltSettings> load() async =>
      saved ?? WalletMeltSettings.defaults;

  @override
  Future<void> save(WalletMeltSettings settings) async {
    saved = settings;
  }
}

String _backupJson({
  List<Map<String, Object?>>? categories,
  List<Map<String, Object?>>? expenses,
  List<Map<String, Object?>>? groceryItems,
  List<Map<String, Object?>>? budgets,
  Map<String, Object?>? settings,
}) {
  return const JsonEncoder().convert({
    'metadata': {
      'format': 'walletmelt.local_json_backup',
      'format_version': 1,
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
  String id = 'restore_cat_1',
  String name = 'Backup Supplies',
  bool isDefault = false,
}) {
  return {
    'id': id,
    'name': name,
    'icon': 'shopping_basket',
    'color': '#123456',
    'is_default': isDefault,
    'created_at': '2026-06-01T00:00:00.000',
    'updated_at': '2026-06-01T00:00:00.000',
  };
}

Map<String, Object?> _expenseJson({
  String id = 'expense_1',
  String categoryId = 'restore_cat_1',
  String? receiptImageUri,
  String? deletedAt,
}) {
  return {
    'id': id,
    'amount': 1200,
    'currency': 'PKR',
    'category_id': categoryId,
    'title': 'Weekly grocery',
    'vendor': 'Local store',
    'date': '2026-06-14T00:00:00.000',
    'notes': 'Backup note',
    'receipt_image_uri': receiptImageUri,
    'is_recurring': false,
    'recurrence_frequency': null,
    'created_at': '2026-06-14T10:00:00.000',
    'updated_at': '2026-06-14T10:00:00.000',
    'deleted_at': deletedAt,
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
  String categoryId = 'restore_cat_1',
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

domain.Category _category({
  required String id,
  String name = 'Backup Supplies',
  bool isDefault = false,
}) {
  return domain.Category(
    id: id,
    name: name,
    icon: 'shopping_basket',
    color: '#123456',
    isDefault: isDefault,
    createdAt: '2026-06-01T00:00:00.000',
    updatedAt: '2026-06-01T00:00:00.000',
  );
}

domain.Expense _expense({
  required String id,
  required String categoryId,
}) {
  return domain.Expense(
    id: id,
    amount: 400,
    currency: 'PKR',
    categoryId: categoryId,
    title: 'Existing',
    date: '2026-06-14T00:00:00.000',
    isRecurring: false,
    createdAt: '2026-06-14T08:00:00.000',
    updatedAt: '2026-06-14T08:00:00.000',
  );
}

CategoryBudget _budget({
  required String id,
  required String categoryId,
}) {
  return CategoryBudget(
    id: id,
    categoryId: categoryId,
    amount: 9000,
    currency: 'PKR',
    month: '2026-06',
    createdAt: '2026-06-01T00:00:00.000',
    updatedAt: '2026-06-01T00:00:00.000',
  );
}
