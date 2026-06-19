import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' as local;
import 'package:wallet_melt/src/data/repositories/budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/expense_repository.dart';
import 'package:wallet_melt/src/services/export/export_file_writer.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_dry_run_planner.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/services/receipt_storage/receipt_storage_service.dart';

class FakeReceiptStorageService extends Fake implements ReceiptStorageService {
  String? deletedUri;
  bool deleteCalled = false;

  @override
  Future<void> delete(String uri) async {
    deletedUri = uri;
    deleteCalled = true;
  }
}

class FakeCategoryRepository extends Fake implements CategoryRepository {
  List<wm.Category> categories = [];
  bool createCustomCalled = false;

  @override
  Future<List<wm.Category>> listCategories() async => categories;

  @override
  Future<wm.Category> createCustom({
    required String name,
    required String icon,
    required String color,
  }) async {
    createCustomCalled = true;
    final category = wm.Category(
      id: 'custom',
      name: name,
      icon: icon,
      color: color,
      isDefault: false,
      createdAt: '2026-06-14',
      updatedAt: '2026-06-14',
    );
    categories.add(category);
    return category;
  }
}

class FakeExpenseRepository extends Fake implements ExpenseRepository {
  List<Expense> active = [];
  List<Expense> deleted = [];
  List<GroceryItem> groceryItems = [];
  Expense? singleExpense;
  bool permanentlyDeleteCalled = false;
  bool softDeleteCalled = false;
  bool restoreCalled = false;
  bool createCalled = false;
  Expense? createdExpense;
  ExpenseDraft? lastDraft;
  bool updateCalled = false;
  Expense? lastUpdatedExpense;
  List<GroceryItemDraft>? lastUpdatedGroceryItems;

  @override
  Future<List<Expense>> listActive() async => active;

  @override
  Future<List<Expense>> listDeleted() async => deleted;

  @override
  Future<List<GroceryItem>> groceryItemsForExpense(String expenseId) async =>
      groceryItems;

  @override
  Future<List<GroceryItem>> listAllGroceryItems() async => groceryItems;

  @override
  Future<Expense?> getById(String id, {bool includeDeleted = false}) async =>
      singleExpense;

  @override
  Future<void> permanentlyDelete(String id) async {
    permanentlyDeleteCalled = true;
  }

  @override
  Future<void> softDelete(String id) async {
    softDeleteCalled = true;
  }

  @override
  Future<void> restore(String id) async {
    restoreCalled = true;
  }

  @override
  Future<Expense> create(ExpenseDraft draft) async {
    createCalled = true;
    lastDraft = draft;
    final expense = createdExpense ??
        Expense(
          id: 'sqflite-created-id',
          amount: draft.amount,
          currency: draft.currency,
          categoryId: draft.categoryId,
          title: draft.title.isEmpty ? 'Household expense' : draft.title,
          date: draft.date.toIso8601String(),
          isRecurring: false,
          createdAt: '2026-06-14',
          updatedAt: '2026-06-14',
        );
    active.add(expense);
    return expense;
  }

  @override
  Future<void> update(Expense expense,
      {List<GroceryItemDraft>? groceryItems}) async {
    updateCalled = true;
    lastUpdatedExpense = expense;
    lastUpdatedGroceryItems = groceryItems;
  }
}

class FakeBudgetRepository extends Fake implements BudgetRepository {
  List<CategoryBudget> budgets = [];
  bool upsertCalled = false;
  bool deleteCalled = false;

  @override
  Future<List<CategoryBudget>> listForMonth(String month) async =>
      budgets.where((b) => b.month == month).toList();

  @override
  Future<List<CategoryBudget>> listAll() async => budgets;

  @override
  Future<void> upsert({
    required String categoryId,
    required double amount,
    required String currency,
    required String month,
  }) async {
    upsertCalled = true;
    final budget = CategoryBudget(
      id: 'sqflite-b',
      categoryId: categoryId,
      amount: amount,
      currency: currency,
      month: month,
      createdAt: '2026-06-14',
      updatedAt: '2026-06-14',
    );
    budgets.add(budget);
  }

  @override
  Future<void> delete(String categoryId, String month) async {
    deleteCalled = true;
    budgets.removeWhere((b) => b.categoryId == categoryId && b.month == month);
  }
}

class FakeDriftCategoryRepository extends Fake
    implements DriftCategoryRepository {
  List<wm.Category>? categories;
  bool shouldThrow = false;
  bool createCustomCalled = false;

  @override
  Future<List<wm.Category>> listCategories() async {
    if (shouldThrow) throw Exception('Drift error');
    return categories ?? [];
  }

  @override
  Future<wm.Category> createCustom({
    required String name,
    required String icon,
    required String color,
  }) async {
    createCustomCalled = true;
    return wm.Category(
      id: 'drift-custom',
      name: name,
      icon: icon,
      color: color,
      isDefault: false,
      createdAt: '2026-06-14',
      updatedAt: '2026-06-14',
    );
  }
}

class FakeDriftBudgetRepository extends Fake implements DriftBudgetRepository {
  List<CategoryBudget>? budgets;
  bool shouldThrowList = false;
  bool shouldThrowListAll = false;
  bool shouldThrowUpsert = false;
  bool shouldThrowDelete = false;
  bool upsertCalled = false;
  bool deleteCalled = false;

  @override
  Future<List<CategoryBudget>> listForMonth(String month) async {
    if (shouldThrowList) throw Exception('Drift error');
    return budgets?.where((b) => b.month == month).toList() ?? [];
  }

  @override
  Future<List<CategoryBudget>> listAll() async {
    if (shouldThrowListAll) throw Exception('Drift error');
    return budgets ?? [];
  }

  @override
  Future<void> upsert({
    required String categoryId,
    required double amount,
    required String currency,
    required String month,
  }) async {
    if (shouldThrowUpsert) throw Exception('Drift error');
    upsertCalled = true;
  }

  @override
  Future<void> delete(String categoryId, String month) async {
    if (shouldThrowDelete) throw Exception('Drift error');
    deleteCalled = true;
  }
}

class FakeDriftExpenseRepository extends Fake
    implements DriftExpenseRepository {
  List<Expense>? active;
  List<Expense>? deleted;
  List<GroceryItem>? groceryItems;
  Expense? singleExpense;
  bool shouldThrowListActive = false;
  bool shouldThrowListDeleted = false;
  bool shouldThrowGroceryItems = false;
  bool shouldThrowListAllGroceryItems = false;
  bool shouldThrowGetById = false;
  bool softDeleteCalled = false;
  bool restoreCalled = false;
  bool shouldThrowSoftDelete = false;
  bool shouldThrowRestore = false;
  bool permanentlyDeleteCalled = false;
  bool shouldThrowPermanentlyDelete = false;
  bool getByIdCalled = false;
  bool createCalled = false;
  bool shouldThrowCreate = false;
  Expense? createdExpense;
  ExpenseDraft? lastDraft;
  bool updateCalled = false;
  bool shouldThrowUpdate = false;
  Expense? lastUpdatedExpense;
  List<GroceryItemDraft>? lastUpdatedGroceryItems;

  @override
  Future<List<Expense>> listActive() async {
    if (shouldThrowListActive) throw Exception('Drift error');
    return active ?? [];
  }

  @override
  Future<List<Expense>> listDeleted() async {
    if (shouldThrowListDeleted) throw Exception('Drift error');
    return deleted ?? [];
  }

  @override
  Future<List<GroceryItem>> groceryItemsForExpense(String expenseId) async {
    if (shouldThrowGroceryItems) throw Exception('Drift error');
    return groceryItems ?? [];
  }

  @override
  Future<List<GroceryItem>> listAllGroceryItems() async {
    if (shouldThrowListAllGroceryItems) throw Exception('Drift error');
    return groceryItems ?? [];
  }

  @override
  Future<Expense?> getById(String id, {bool includeDeleted = false}) async {
    getByIdCalled = true;
    if (shouldThrowGetById) throw Exception('Drift error');
    return singleExpense;
  }

  @override
  Future<void> softDelete(String id) async {
    if (shouldThrowSoftDelete) throw Exception('Drift error');
    softDeleteCalled = true;
  }

  @override
  Future<void> restore(String id) async {
    if (shouldThrowRestore) throw Exception('Drift error');
    restoreCalled = true;
  }

  @override
  Future<void> permanentlyDelete(String id) async {
    if (shouldThrowPermanentlyDelete) throw Exception('Drift error');
    permanentlyDeleteCalled = true;
  }

  @override
  Future<Expense> create(ExpenseDraft draft) async {
    createCalled = true;
    lastDraft = draft;
    if (shouldThrowCreate) throw Exception('Drift error');
    final expense = createdExpense ??
        Expense(
          id: 'drift-created-id',
          amount: draft.amount,
          currency: draft.currency,
          categoryId: draft.categoryId,
          title: draft.title.isEmpty ? 'Household expense' : draft.title,
          date: draft.date.toIso8601String(),
          isRecurring: false,
          createdAt: '2026-06-14',
          updatedAt: '2026-06-14',
        );
    return expense;
  }

  @override
  Future<void> update(Expense expense,
      {List<GroceryItemDraft>? groceryItems}) async {
    updateCalled = true;
    lastUpdatedExpense = expense;
    lastUpdatedGroceryItems = groceryItems;
    if (shouldThrowUpdate) throw Exception('Drift error');
  }
}

class FakeWalletMeltJsonRestoreService extends WalletMeltJsonRestoreService {
  bool restoreCalled = false;
  WalletMeltJsonRestoreResult result =
      const WalletMeltJsonRestoreResult(success: true);

  @override
  Future<WalletMeltJsonRestoreResult> restoreSafeMerge({
    required String jsonText,
    required RestoreDryRunPlan dryRunPlan,
    required WalletMeltJsonRestoreOptions options,
    required ExportFileResult safetyBackup,
    local.WalletMeltDatabase? database,
  }) async {
    restoreCalled = true;
    return result;
  }
}

ExportFileResult _safetyBackup() {
  return ExportFileResult(
    path: 'memory/safety.json',
    fileName: 'safety.json',
    mimeType: ExportFileWriter.jsonMimeType,
    byteCount: 16,
    createdAt: DateTime(2026, 6, 15),
  );
}

void main() {
  group('AppState Migrated Read Paths and Fallback', () {
    late FakeCategoryRepository categoryRepo;
    late FakeExpenseRepository expenseRepo;
    late FakeBudgetRepository budgetRepo;
    late FakeDriftCategoryRepository driftCategoryRepo;
    late FakeDriftBudgetRepository driftBudgetRepo;
    late FakeDriftExpenseRepository driftExpenseRepo;

    final mockCategory = wm.Category(
      id: 'food',
      name: 'Food',
      icon: 'restaurant',
      color: '#FF0000',
      isDefault: true,
      createdAt: '2026-06-14',
      updatedAt: '2026-06-14',
    );

    final mockBudget = CategoryBudget(
      id: 'b1',
      categoryId: 'food',
      amount: 500,
      currency: 'USD',
      month: '2026-06',
      createdAt: '2026-06-14',
      updatedAt: '2026-06-14',
    );

    final mockExpense = Expense(
      id: '1',
      amount: 100,
      currency: 'USD',
      categoryId: 'food',
      title: 'Lunch',
      date: '2026-06-14',
      isRecurring: false,
      createdAt: '2026-06-14',
      updatedAt: '2026-06-14',
    );

    final mockDeletedExpense = Expense(
      id: '2',
      amount: 200,
      currency: 'USD',
      categoryId: 'travel',
      title: 'Taxi',
      date: '2026-06-14',
      isRecurring: false,
      createdAt: '2026-06-14',
      updatedAt: '2026-06-14',
      deletedAt: '2026-06-14',
    );

    final mockGroceryItem = GroceryItem(
      id: 'g1',
      expenseId: '1',
      name: 'Milk',
      amount: 10,
      createdAt: '2026-06-14',
    );

    setUp(() {
      categoryRepo = FakeCategoryRepository();
      expenseRepo = FakeExpenseRepository();
      budgetRepo = FakeBudgetRepository();
      driftCategoryRepo = FakeDriftCategoryRepository();
      driftBudgetRepo = FakeDriftBudgetRepository();
      driftExpenseRepo = FakeDriftExpenseRepository();
    });

    test('restore aborts before mutation when Drift runtime is unavailable',
        () async {
      final restoreService = FakeWalletMeltJsonRestoreService();
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
        requiresDriftRestoreRuntime: true,
      );

      final result = await appState.restoreJsonBackupSafeMerge(
        jsonText: '{}',
        dryRunPlan: RestoreDryRunPlan.invalid('unused'),
        safetyBackup: _safetyBackup(),
        restoreService: restoreService,
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Drift database runtime'));
      expect(restoreService.restoreCalled, isFalse);
    });

    test('restore refreshes AppState only after successful commit', () async {
      final restoredCategory = wm.Category(
        id: 'restored',
        name: 'Restored',
        icon: 'restore',
        color: '#123456',
        isDefault: false,
        createdAt: '2026-06-15',
        updatedAt: '2026-06-15',
      );
      final restoreService = FakeWalletMeltJsonRestoreService();
      categoryRepo.categories = [];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: null,
        driftBudgetRepository: null,
        driftExpenseRepository: null,
      );

      await appState.refresh();
      expect(appState.categories, isEmpty);

      categoryRepo.categories = [restoredCategory];
      await appState.restoreJsonBackupSafeMerge(
        jsonText: '{}',
        dryRunPlan: RestoreDryRunPlan.invalid('unused'),
        safetyBackup: _safetyBackup(),
        restoreService: restoreService,
      );

      expect(restoreService.restoreCalled, isTrue);
      expect(appState.categories, [restoredCategory]);

      restoreService.result =
          WalletMeltJsonRestoreResult.failure('simulated failure');
      categoryRepo.categories = [];
      await appState.restoreJsonBackupSafeMerge(
        jsonText: '{}',
        dryRunPlan: RestoreDryRunPlan.invalid('unused'),
        safetyBackup: _safetyBackup(),
        restoreService: restoreService,
      );

      expect(appState.categories, [restoredCategory]);
    });

    test('refresh() loads expenses from Drift when available', () async {
      driftExpenseRepo.active = [mockExpense];
      driftExpenseRepo.deleted = [mockDeletedExpense];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.refresh();

      expect(appState.expenses, [mockExpense]);
      expect(appState.deletedExpenses, [mockDeletedExpense]);
    });

    test(
        'refresh() falls back to sqflite when Drift active/deleted lists throw',
        () async {
      driftExpenseRepo.shouldThrowListActive = true;
      driftExpenseRepo.shouldThrowListDeleted = true;
      expenseRepo.active = [mockExpense];
      expenseRepo.deleted = [mockDeletedExpense];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.refresh();

      expect(appState.expenses, [mockExpense]);
      expect(appState.deletedExpenses, [mockDeletedExpense]);
    });

    test('groceryItemsForExpense() reads from Drift when available', () async {
      driftExpenseRepo.groceryItems = [mockGroceryItem];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.groceryItemsForExpense('1');
      expect(result, [mockGroceryItem]);
    });

    test('groceryItemsForExpense() falls back to sqflite when Drift throws',
        () async {
      driftExpenseRepo.shouldThrowGroceryItems = true;
      expenseRepo.groceryItems = [mockGroceryItem];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.groceryItemsForExpense('1');
      expect(result, [mockGroceryItem]);
    });

    test('listAllGroceryItemsForExport() reads from Drift when available',
        () async {
      driftExpenseRepo.groceryItems = [mockGroceryItem];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.listAllGroceryItemsForExport();
      expect(result, [mockGroceryItem]);
    });

    test(
        'listAllGroceryItemsForExport() falls back to sqflite when Drift throws',
        () async {
      driftExpenseRepo.shouldThrowListAllGroceryItems = true;
      expenseRepo.groceryItems = [mockGroceryItem];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.listAllGroceryItemsForExport();
      expect(result, [mockGroceryItem]);
    });

    test(
        'permanentlyDeleteExpense() uses Drift permanentlyDelete when available',
        () async {
      driftExpenseRepo.singleExpense = mockExpense;
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.permanentlyDeleteExpense('1');

      expect(driftExpenseRepo.permanentlyDeleteCalled, isTrue);
      expect(expenseRepo.permanentlyDeleteCalled, isFalse);
    });

    test(
        'permanentlyDeleteExpense() falls back to sqflite when Drift permanentlyDelete throws',
        () async {
      driftExpenseRepo.singleExpense = mockExpense;
      driftExpenseRepo.shouldThrowPermanentlyDelete = true;
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.permanentlyDeleteExpense('1');

      expect(expenseRepo.permanentlyDeleteCalled, isTrue);
    });

    test(
        'permanentlyDeleteExpense() uses sqflite when Drift repository is unavailable',
        () async {
      expenseRepo.singleExpense = mockExpense;
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: null,
      );

      await appState.permanentlyDeleteExpense('1');

      expect(expenseRepo.permanentlyDeleteCalled, isTrue);
    });

    test(
        'permanentlyDeleteExpense() performs Drift-first deleted-expense lookup before deletion',
        () async {
      driftExpenseRepo.singleExpense = mockExpense;
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.permanentlyDeleteExpense('1');

      expect(driftExpenseRepo.getByIdCalled, isTrue);
    });

    test('permanentlyDeleteExpense() calls refresh() after successful deletion',
        () async {
      driftExpenseRepo.singleExpense = mockExpense;
      driftExpenseRepo.active = [mockExpense];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.refresh();
      expect(appState.expenses, [mockExpense]);

      driftExpenseRepo.active = [];

      await appState.permanentlyDeleteExpense('1');

      expect(appState.expenses, isEmpty);
    });

    test(
        'permanentlyDeleteExpense() preserves receipt cleanup behavior for expenses with receipt paths',
        () async {
      final mockExpenseWithReceipt = Expense(
        id: '1',
        amount: 100,
        currency: 'USD',
        categoryId: 'food',
        title: 'Lunch',
        date: '2026-06-14',
        isRecurring: false,
        createdAt: '2026-06-14',
        updatedAt: '2026-06-14',
        receiptImageUri: 'file:///receipts/test.jpg',
      );
      driftExpenseRepo.singleExpense = mockExpenseWithReceipt;

      final fakeReceiptStorage = FakeReceiptStorageService();

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
        receiptStorageService: fakeReceiptStorage,
      );

      await appState.permanentlyDeleteExpense('1');

      expect(fakeReceiptStorage.deleteCalled, isTrue);
      expect(fakeReceiptStorage.deletedUri, 'file:///receipts/test.jpg');
    });

    test(
        'permanentlyDeleteExpense() missing expense behavior remains unchanged',
        () async {
      driftExpenseRepo.singleExpense = null;
      final fakeReceiptStorage = FakeReceiptStorageService();

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
        receiptStorageService: fakeReceiptStorage,
      );

      await appState.permanentlyDeleteExpense('1');

      expect(fakeReceiptStorage.deleteCalled, isFalse);
      expect(driftExpenseRepo.permanentlyDeleteCalled, isTrue);
    });

    test('refresh() loads categories from Drift when available', () async {
      driftCategoryRepo.categories = [mockCategory];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.refresh();

      expect(appState.categories, [mockCategory]);
    });

    test('refresh() falls back to sqflite category read when Drift throws',
        () async {
      driftCategoryRepo.shouldThrow = true;
      categoryRepo.categories = [mockCategory];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.refresh();

      expect(appState.categories, [mockCategory]);
    });

    test('refresh() loads current month budgets from Drift when available',
        () async {
      driftBudgetRepo.budgets = [mockBudget];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      // Selected month defaults to current month, which matches budget month key '2026-06' under current metadata year
      // Let's force check the month matching
      appState.selectedMonth = DateTime(2026, 6);
      await appState.refresh();

      expect(appState.currentBudgets.map((b) => b.id), ['b1']);
    });

    test('refresh() falls back to sqflite budget read when Drift throws',
        () async {
      driftBudgetRepo.shouldThrowList = true;
      budgetRepo.budgets = [mockBudget];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      appState.selectedMonth = DateTime(2026, 6);
      await appState.refresh();

      expect(appState.currentBudgets.map((b) => b.id), ['b1']);
    });

    test('listAllBudgetsForExport() reads from Drift when available', () async {
      driftBudgetRepo.budgets = [mockBudget];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.listAllBudgetsForExport();
      expect(result, [mockBudget]);
    });

    test('listAllBudgetsForExport() falls back to sqflite when Drift throws',
        () async {
      driftBudgetRepo.shouldThrowListAll = true;
      budgetRepo.budgets = [mockBudget];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.listAllBudgetsForExport();
      expect(result, [mockBudget]);
    });

    test(
        'previousMonth() and nextMonth() refresh budgets using Drift-first behavior',
        () async {
      final juneBudget = mockBudget;
      final mayBudget = CategoryBudget(
        id: 'b2',
        categoryId: 'food',
        amount: 400,
        currency: 'USD',
        month: '2026-05',
        createdAt: '2026-06-14',
        updatedAt: '2026-06-14',
      );
      driftBudgetRepo.budgets = [juneBudget, mayBudget];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      appState.selectedMonth = DateTime(2026, 6);

      // Navigate to previous month
      await appState.previousMonth();
      expect(appState.selectedMonth.month, 5);
      expect(appState.currentBudgets.map((b) => b.id), ['b2']);

      // Navigate to next month
      await appState.nextMonth();
      expect(appState.selectedMonth.month, 6);
      expect(appState.currentBudgets.map((b) => b.id), ['b1']);
    });

    test('setBudget() writes through DriftBudgetRepository when available',
        () async {
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      appState.selectedMonth = DateTime(2026, 6);
      await appState.setBudget('food', 600);

      expect(driftBudgetRepo.upsertCalled, isTrue);
      expect(budgetRepo.upsertCalled, isFalse);
    });

    test(
        'setBudget() falls back to sqflite BudgetRepository when Drift upsert throws',
        () async {
      driftBudgetRepo.shouldThrowUpsert = true;

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      appState.selectedMonth = DateTime(2026, 6);
      await appState.setBudget('food', 600);

      expect(budgetRepo.upsertCalled, isTrue);
    });

    test('clearBudget() deletes through DriftBudgetRepository when available',
        () async {
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      appState.selectedMonth = DateTime(2026, 6);
      await appState.clearBudget('food');

      expect(driftBudgetRepo.deleteCalled, isTrue);
      expect(budgetRepo.deleteCalled, isFalse);
    });

    test(
        'clearBudget() falls back to sqflite BudgetRepository when Drift delete throws',
        () async {
      driftBudgetRepo.shouldThrowDelete = true;

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      appState.selectedMonth = DateTime(2026, 6);
      await appState.clearBudget('food');

      expect(budgetRepo.deleteCalled, isTrue);
    });

    test('softDeleteExpense uses DriftExpenseRepository when available',
        () async {
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.softDeleteExpense('1');

      expect(driftExpenseRepo.softDeleteCalled, isTrue);
      expect(expenseRepo.softDeleteCalled, isFalse);
    });

    test('softDeleteExpense falls back to sqflite when Drift throws', () async {
      driftExpenseRepo.shouldThrowSoftDelete = true;

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.softDeleteExpense('1');

      expect(expenseRepo.softDeleteCalled, isTrue);
    });

    test('restoreExpense uses DriftExpenseRepository when available', () async {
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.restoreExpense('1');

      expect(driftExpenseRepo.restoreCalled, isTrue);
      expect(expenseRepo.restoreCalled, isFalse);
    });

    test('restoreExpense falls back to sqflite when Drift throws', () async {
      driftExpenseRepo.shouldThrowRestore = true;

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.restoreExpense('1');

      expect(expenseRepo.restoreCalled, isTrue);
    });

    test('softDeleteExpense still calls refresh after write', () async {
      driftExpenseRepo.active = [mockExpense];
      driftExpenseRepo.deleted = [];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.refresh();
      expect(appState.expenses, [mockExpense]);

      driftExpenseRepo.active = [];
      driftExpenseRepo.deleted = [mockDeletedExpense];

      await appState.softDeleteExpense('1');

      expect(appState.expenses, isEmpty);
      expect(appState.deletedExpenses, [mockDeletedExpense]);
    });

    test('restoreExpense still calls refresh after write', () async {
      driftExpenseRepo.active = [];
      driftExpenseRepo.deleted = [mockDeletedExpense];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.refresh();
      expect(appState.deletedExpenses, [mockDeletedExpense]);

      driftExpenseRepo.active = [mockExpense];
      driftExpenseRepo.deleted = [];

      await appState.restoreExpense('2');

      expect(appState.expenses, [mockExpense]);
      expect(appState.deletedExpenses, isEmpty);
    });

    test('addExpense() uses Drift create when available', () async {
      final draft = ExpenseDraft(
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: DateTime(2026, 6, 14),
      );

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.addExpense(draft);

      expect(driftExpenseRepo.createCalled, isTrue);
      expect(expenseRepo.createCalled, isFalse);
      expect(result.id, 'drift-created-id');
    });

    test('addExpense() falls back to sqflite when Drift throws', () async {
      final draft = ExpenseDraft(
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: DateTime(2026, 6, 14),
      );

      driftExpenseRepo.shouldThrowCreate = true;

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.addExpense(draft);

      expect(driftExpenseRepo.createCalled, isTrue);
      expect(expenseRepo.createCalled, isTrue);
      expect(result.id, 'sqflite-created-id');
    });

    test('addExpense() uses sqflite when Drift is unavailable', () async {
      final draft = ExpenseDraft(
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: DateTime(2026, 6, 14),
      );

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: null,
      );

      final result = await appState.addExpense(draft);

      expect(expenseRepo.createCalled, isTrue);
      expect(result.id, 'sqflite-created-id');
    });

    test('addExpense() calls refresh() after successful creation', () async {
      final draft = ExpenseDraft(
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: DateTime(2026, 6, 14),
      );

      final created = Expense(
        id: 'drift-created-id',
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: '2026-06-14',
        isRecurring: false,
        createdAt: '2026-06-14',
        updatedAt: '2026-06-14',
      );

      driftExpenseRepo.createdExpense = created;
      driftExpenseRepo.active = [created];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      expect(appState.expenses, isEmpty);

      await appState.addExpense(draft);

      expect(appState.expenses, [created]);
    });

    test('addExpense() preserves grocery itemization payloads', () async {
      final groceryItems = const [
        GroceryItemDraft(name: 'Milk', amount: 520),
        GroceryItemDraft(name: 'Eggs', amount: 420),
      ];
      final draft = ExpenseDraft(
        amount: 940,
        currency: 'PKR',
        categoryId: 'grocery',
        title: 'Grocery shopping',
        date: DateTime(2026, 6, 14),
        groceryItems: groceryItems,
      );

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.addExpense(draft);

      expect(driftExpenseRepo.lastDraft?.groceryItems, groceryItems);
    });

    test('addExpense() preserves receipt URI/path behavior', () async {
      final draft = ExpenseDraft(
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: DateTime(2026, 6, 14),
        receiptImageUri: 'file:///receipts/test.jpg',
      );

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.addExpense(draft);

      expect(driftExpenseRepo.lastDraft?.receiptImageUri,
          'file:///receipts/test.jpg');
    });

    test(
        'addExpense() Drift failure does not prevent sqflite fallback from creating the expense',
        () async {
      final draft = ExpenseDraft(
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: DateTime(2026, 6, 14),
      );

      driftExpenseRepo.shouldThrowCreate = true;

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      final result = await appState.addExpense(draft);

      expect(driftExpenseRepo.createCalled, isTrue);
      expect(expenseRepo.createCalled, isTrue);
      expect(result.id, 'sqflite-created-id');
    });

    test('addExpense() read state remains consistent after creation', () async {
      final draft = ExpenseDraft(
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: DateTime(2026, 6, 14),
      );

      final created = Expense(
        id: 'drift-created-id',
        amount: 150,
        currency: 'USD',
        categoryId: 'food',
        title: 'Dinner',
        date: '2026-06-14',
        isRecurring: false,
        createdAt: '2026-06-14',
        updatedAt: '2026-06-14',
      );

      driftExpenseRepo.createdExpense = created;
      driftExpenseRepo.active = [];
      driftCategoryRepo.categories = [mockCategory];
      driftBudgetRepo.budgets = [mockBudget];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      appState.selectedMonth = DateTime(2026, 6);

      await appState.refresh();
      expect(appState.categories, [mockCategory]);
      expect(appState.currentBudgets.map((b) => b.id), ['b1']);
      expect(appState.expenses, isEmpty);

      driftExpenseRepo.active = [created];

      await appState.addExpense(draft);

      expect(appState.categories, [mockCategory]);
      expect(appState.currentBudgets.map((b) => b.id), ['b1']);
      expect(appState.expenses, [created]);
    });

    test('updateExpense() uses Drift update when available', () async {
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.updateExpense(mockExpense);

      expect(driftExpenseRepo.updateCalled, isTrue);
      expect(expenseRepo.updateCalled, isFalse);
    });

    test('updateExpense() falls back to sqflite when Drift throws', () async {
      driftExpenseRepo.shouldThrowUpdate = true;

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.updateExpense(mockExpense);

      expect(driftExpenseRepo.updateCalled, isTrue);
      expect(expenseRepo.updateCalled, isTrue);
    });

    test('updateExpense() uses sqflite when Drift is unavailable', () async {
      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: null,
      );

      await appState.updateExpense(mockExpense);

      expect(expenseRepo.updateCalled, isTrue);
    });

    test('updateExpense() still calls refresh() after successful update',
        () async {
      final updatedExpense = mockExpense.copyWith(amount: 150);
      driftExpenseRepo.active = [];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.refresh();
      expect(appState.expenses, isEmpty);

      driftExpenseRepo.active = [updatedExpense];

      await appState.updateExpense(mockExpense);

      expect(appState.expenses, [updatedExpense]);
    });

    test('updateExpense() preserves grocery itemization payloads', () async {
      final groceryItems = const [
        GroceryItemDraft(name: 'Bread', amount: 300),
      ];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.updateExpense(mockExpense, groceryItems: groceryItems);

      expect(driftExpenseRepo.lastUpdatedGroceryItems, groceryItems);
    });

    test('updateExpense() preserves receipt URI/path behavior', () async {
      final updatedExpense =
          mockExpense.copyWith(receiptImageUri: 'file:///receipts/updated.jpg');

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.updateExpense(updatedExpense);

      expect(driftExpenseRepo.lastUpdatedExpense?.receiptImageUri,
          'file:///receipts/updated.jpg');
    });

    test(
        'updateExpense() Drift failure does not prevent sqflite fallback from updating the expense',
        () async {
      driftExpenseRepo.shouldThrowUpdate = true;
      final updatedExpense = mockExpense.copyWith(amount: 180);

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.updateExpense(updatedExpense);

      expect(driftExpenseRepo.updateCalled, isTrue);
      expect(expenseRepo.updateCalled, isTrue);
      expect(expenseRepo.lastUpdatedExpense?.amount, 180);
    });

    test('updateExpense() read state remains consistent after update',
        () async {
      driftCategoryRepo.categories = [mockCategory];
      driftBudgetRepo.budgets = [mockBudget];
      driftExpenseRepo.active = [mockExpense];

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      appState.selectedMonth = DateTime(2026, 6);

      await appState.refresh();
      expect(appState.categories, [mockCategory]);
      expect(appState.currentBudgets.map((b) => b.id), ['b1']);
      expect(appState.expenses, [mockExpense]);

      final updatedExpense = mockExpense.copyWith(amount: 250);
      driftExpenseRepo.active = [updatedExpense];

      await appState.updateExpense(updatedExpense);

      expect(appState.categories, [mockCategory]);
      expect(appState.currentBudgets.map((b) => b.id), ['b1']);
      expect(appState.expenses, [updatedExpense]);
    });

    test('updateExpense() missing-expense behavior remains unchanged',
        () async {
      final nonExistentExpense = mockExpense.copyWith(id: 'non-existent');

      final appState = AppState.test(
        categoryRepository: categoryRepo,
        expenseRepository: expenseRepo,
        budgetRepository: budgetRepo,
        driftCategoryRepository: driftCategoryRepo,
        driftBudgetRepository: driftBudgetRepo,
        driftExpenseRepository: driftExpenseRepo,
      );

      await appState.updateExpense(nonExistentExpense);

      expect(driftExpenseRepo.updateCalled, isTrue);
      expect(driftExpenseRepo.lastUpdatedExpense?.id, 'non-existent');
    });
  });
}
