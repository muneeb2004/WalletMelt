import 'dart:io';
import 'package:flutter/foundation.dart';

import '../data/db/app_database.dart';
import '../data/local/wallet_melt_database.dart' as local;
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/drift/drift_budget_repository.dart';
import '../data/repositories/drift/drift_category_repository.dart';
import '../data/repositories/drift/drift_expense_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../services/receipt_storage/receipt_storage_service.dart';
import '../services/export/export_file_writer.dart';
import '../services/export/wallet_melt_json_restore_dry_run_planner.dart';
import '../services/export/wallet_melt_json_restore_plan.dart';
import '../services/export/wallet_melt_json_restore_service.dart';

import '../services/settings/settings_service.dart';
import '../types/budget.dart';
import '../types/category.dart' as wm;
import '../types/expense.dart';
import '../types/grocery_item.dart';
import '../types/settings.dart';
import '../utils/date_utils.dart';
import '../utils/insights.dart';

import 'package:uuid/uuid.dart';
import '../types/debt.dart' as wm_debt;
import '../types/grocery_template.dart' as wm_template;
import '../data/repositories/drift/drift_debt_repository.dart';
import '../data/repositories/drift/drift_grocery_template_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    SettingsService? settingsService,
    ReceiptStorageService? receiptStorageService,
  })  : _settingsService = settingsService ?? SettingsService(),
        _requiresDriftRestoreRuntime = true,
        receiptStorage = receiptStorageService ?? LocalReceiptStorageService();

  @visibleForTesting
  AppState.test({
    required CategoryRepository categoryRepository,
    required ExpenseRepository expenseRepository,
    required BudgetRepository budgetRepository,
    DriftCategoryRepository? driftCategoryRepository,
    DriftBudgetRepository? driftBudgetRepository,
    DriftExpenseRepository? driftExpenseRepository,
    SettingsService? settingsService,
    ReceiptStorageService? receiptStorageService,
    bool requiresDriftRestoreRuntime = false,
  })  : _settingsService = settingsService ?? SettingsService(),
        _requiresDriftRestoreRuntime = requiresDriftRestoreRuntime,
        receiptStorage = receiptStorageService ?? LocalReceiptStorageService() {
    _categoryRepository = categoryRepository;
    _expenseRepository = expenseRepository;
    _budgetRepository = budgetRepository;
    _driftCategoryRepository = driftCategoryRepository;
    _driftBudgetRepository = driftBudgetRepository;
    _driftExpenseRepository = driftExpenseRepository;
    isLoading = false;
  }

  final SettingsService _settingsService;
  final ReceiptStorageService receiptStorage;
  final bool _requiresDriftRestoreRuntime;

  late CategoryRepository _categoryRepository;
  late ExpenseRepository _expenseRepository;
  late BudgetRepository _budgetRepository;
  local.WalletMeltDatabase? _driftDatabase;
  DriftCategoryRepository? _driftCategoryRepository;
  DriftBudgetRepository? _driftBudgetRepository;
  DriftExpenseRepository? _driftExpenseRepository;
  DriftDebtRepository? _driftDebtRepository;
  DriftGroceryTemplateRepository? _driftGroceryTemplateRepository;

  List<wm_debt.DebtRecord> debts = const [];
  List<wm_template.GroceryTemplate> groceryTemplates = const [];

  WalletMeltSettings settings = WalletMeltSettings.defaults;
  List<wm.Category> categories = const [];
  List<Expense> _expenses = const [];
  List<Expense> get expenses => _expenses;
  set expenses(List<Expense> value) {
    _expenses = value;
    _updateCurrentMonthExpenses();
  }
  List<Expense> _deletedExpenses = const [];
  bool _deletedExpensesLoaded = false;
  List<Expense> get deletedExpenses => _deletedExpenses;

  set deletedExpenses(List<Expense> value) {
    _deletedExpenses = value;
    _deletedExpensesLoaded = true;
  }

  Future<List<Expense>> loadDeletedExpenses() async {
    if (!_deletedExpensesLoaded) {
      _deletedExpenses = await _listDeletedExpenses();
      _deletedExpensesLoaded = true;
      notifyListeners();
    }
    return _deletedExpenses;
  }
  List<CategoryBudget> currentBudgets = const [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get selectedMonth => _selectedMonth;
  set selectedMonth(DateTime value) {
    _selectedMonth = value;
    _updateCurrentMonthExpenses();
  }
  bool isLoading = true;
  String? errorMessage;

  double? _cachedTotalSpent;
  MonthlyInsights? _cachedInsights;

  List<Expense> _currentMonthExpenses = const [];
  List<Expense> get currentMonthExpenses => _currentMonthExpenses;

  Map<String, wm.Category>? _categoryMap;

  void _clearCache() {
    _cachedTotalSpent = null;
    _cachedInsights = null;
    _categoryMap = null;
    _currentMonthExpenses = const [];
  }

  void _updateCurrentMonthExpenses() {
    _currentMonthExpenses = expenses.where((e) {
      if (e.deletedAt != null) return false;
      try {
        return isSameMonth(parseIsoDate(e.date), selectedMonth);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  String get currentMonthKey => monthKey(selectedMonth);

  MonthlyInsights get monthlyInsights {
    if (_cachedInsights != null) return _cachedInsights!;
    _cachedInsights = buildMonthlyInsights(
      expenses: expenses,
      categories: categories,
      budgets: currentBudgets,
      month: selectedMonth,
    );
    return _cachedInsights!;
  }

  Future<void> initialize() async {
    try {
      isLoading = true;
      notifyListeners();
      final db = await AppDatabase.instance.database;
      _categoryRepository = CategoryRepository(db);
      _expenseRepository = ExpenseRepository(db);
      _budgetRepository = BudgetRepository(db);
      await _initializeDriftReadRepositories();
      settings = await _settingsService.load();
      await refresh();
    } catch (error) {
      errorMessage = 'WalletMelt could not load local data.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _clearCache();
    if (_deletedExpensesLoaded) {
      _deletedExpenses = await _listDeletedExpenses();
      _deletedExpensesLoaded = true;
    } else {
      _deletedExpensesLoaded = false;
      _deletedExpenses = const [];
    }
    categories = await _listCategories();
    expenses = await _listActiveExpenses();
    currentBudgets = await _listBudgetsForMonth(currentMonthKey);
    _updateCurrentMonthExpenses();

    final debtRepo = _driftDebtRepository;
    if (debtRepo != null) {
      debts = await debtRepo.listAll();
    }
    final templateRepo = _driftGroceryTemplateRepository;
    if (templateRepo != null) {
      groceryTemplates = await templateRepo.listAll();
    }

    notifyListeners();
  }

  Future<void> completeOnboarding(String currency) async {
    settings =
        settings.copyWith(currency: currency, hasCompletedOnboarding: true);
    await _settingsService.save(settings);
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    _clearCache();
    settings = settings.copyWith(currency: currency);
    await _settingsService.save(settings);
    notifyListeners();
  }

  Future<void> updateTheme(ThemePreference themePreference) async {
    settings = settings.copyWith(themePreference: themePreference);
    await _settingsService.save(settings);
    notifyListeners();
  }

  Future<void> recordExportedAt(DateTime exportedAt) async {
    settings = settings.copyWith(lastExportedAt: exportedAt.toIso8601String());
    await _settingsService.save(settings);
    notifyListeners();
  }

  double? getMonthlyBudgetAmount() {
    return settings.monthlyBudgetAmount;
  }

  Future<void> setMonthlyBudgetAmount(double amount) async {
    _clearCache();
    settings = settings.copyWith(monthlyBudgetAmount: amount);
    await _settingsService.save(settings);
    notifyListeners();
  }

  Future<void> clearMonthlyBudgetAmount() async {
    _clearCache();
    settings = settings.copyWith(clearMonthlyBudget: true);
    await _settingsService.save(settings);
    notifyListeners();
  }

  double getCurrentMonthTotalSpent() {
    if (_cachedTotalSpent != null) return _cachedTotalSpent!;
    _cachedTotalSpent = _currentMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    return _cachedTotalSpent!;
  }

  double? getCurrentMonthBudgetRemaining() {
    final budget = getMonthlyBudgetAmount();
    if (budget == null) return null;
    return budget - getCurrentMonthTotalSpent();
  }

  Future<void> setCategoryBudget({
    required String categoryId,
    required double amount,
    required String month,
  }) async {
    await _upsertBudget(
      categoryId: categoryId,
      amount: amount,
      currency: settings.currency,
      month: month,
    );
    await refresh();
  }

  Future<void> clearCategoryBudget({
    required String categoryId,
    required String month,
  }) async {
    await _deleteBudget(categoryId, month);
    await refresh();
  }

  Future<WalletMeltJsonRestoreResult> restoreJsonBackup({
    required String jsonText,
    required RestoreDryRunPlan dryRunPlan,
    required ExportFileResult safetyBackup,
    required WalletMeltJsonRestoreService restoreService,
    required WalletMeltJsonRestoreOptions options,
    Directory? zipExtractDir,
  }) async {
    if (_driftDatabase == null && _requiresDriftRestoreRuntime) {
      return WalletMeltJsonRestoreResult.failure(
        'Restore requires an available Drift database runtime.',
      );
    }
    final WalletMeltJsonRestoreResult result;
    if (options.mode == RestoreMode.fullReplace) {
      result = await restoreService.restoreFullReplace(
        jsonText: jsonText,
        dryRunPlan: dryRunPlan,
        options: options,
        safetyBackup: safetyBackup,
        database: _driftDatabase,
        zipExtractDir: zipExtractDir,
      );
    } else {
      result = await restoreService.restoreSafeMerge(
        jsonText: jsonText,
        dryRunPlan: dryRunPlan,
        options: options,
        safetyBackup: safetyBackup,
        database: _driftDatabase,
        zipExtractDir: zipExtractDir,
      );
    }
    if (result.success) {
      await refresh();
    }
    return result;
  }

  Future<WalletMeltJsonRestoreResult> restoreJsonBackupSafeMerge({
    required String jsonText,
    required RestoreDryRunPlan dryRunPlan,
    required ExportFileResult safetyBackup,
    required WalletMeltJsonRestoreService restoreService,
    WalletMeltJsonRestoreOptions options =
        const WalletMeltJsonRestoreOptions(confirmed: true),
  }) async {
    return restoreJsonBackup(
      jsonText: jsonText,
      dryRunPlan: dryRunPlan,
      safetyBackup: safetyBackup,
      restoreService: restoreService,
      options: options,
    );
  }


  Future<wm.Category> addCategory(
      {required String name,
      required String icon,
      required String color}) async {
    final category = await _categoryRepository.createCustom(
        name: name, icon: icon, color: color);
    await refresh();
    return category;
  }

  Future<Expense> addExpense(ExpenseDraft draft) async {
    final expense = await _addExpense(draft);
    await refresh();
    return expense;
  }

  Future<Expense> _addExpense(ExpenseDraft draft) async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        return await repository.create(draft);
      } catch (_) {
        // Fall through to the proven sqflite path.
      }
    }
    return _expenseRepository.create(draft);
  }

  Future<void> updateExpense(Expense expense,
      {List<GroceryItemDraft>? groceryItems}) async {
    await _updateExpense(expense, groceryItems: groceryItems);
    await refresh();
  }

  Future<void> _updateExpense(Expense expense,
      {List<GroceryItemDraft>? groceryItems}) async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        await repository.update(expense, groceryItems: groceryItems);
        return;
      } catch (_) {
        // Fall through to the proven sqflite path.
      }
    }
    await _expenseRepository.update(expense, groceryItems: groceryItems);
  }

  Future<List<GroceryItem>> groceryItemsForExpense(String expenseId) async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        return await repository.groceryItemsForExpense(expenseId);
      } catch (_) {
        // Fall through to the proven sqflite path if the new read path fails.
      }
    }
    return _expenseRepository.groceryItemsForExpense(expenseId);
  }

  Future<List<GroceryItem>> listAllGroceryItemsForExport() async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        return await repository.listAllGroceryItems();
      } catch (_) {
        // Fall through to the proven sqflite path if the new read path fails.
      }
    }
    return _expenseRepository.listAllGroceryItems();
  }

  Future<List<CategoryBudget>> listAllBudgetsForExport() async {
    final repository = _driftBudgetRepository;
    if (repository != null) {
      try {
        return await repository.listAll();
      } catch (_) {
        // Fall through to the proven sqflite path if the new read path fails.
      }
    }
    return _budgetRepository.listAll();
  }

  Future<void> addDebt(wm_debt.DebtRecord debt) async {
    final repo = _driftDebtRepository;
    if (repo != null) {
      await repo.createDebt(debt);
      await refresh();
    }
  }

  Future<void> deleteDebt(String id) async {
    final repo = _driftDebtRepository;
    if (repo != null) {
      await repo.deleteDebt(id);
      await refresh();
    }
  }

  Future<void> addRepayment({
    required String debtId,
    required double amount,
    String? notes,
  }) async {
    final repo = _driftDebtRepository;
    if (repo != null) {
      final repayment = wm_debt.DebtRepayment(
        id: const Uuid().v4(),
        debtId: debtId,
        amount: amount,
        createdAt: DateTime.now().toIso8601String(),
        notes: notes,
      );
      await repo.addRepayment(repayment);
      await refresh();
    }
  }

  Future<List<wm_debt.DebtRepayment>> repaymentsForDebt(String debtId) async {
    final repo = _driftDebtRepository;
    if (repo != null) {
      return repo.getRepayments(debtId);
    }
    return const [];
  }

  Future<wm_debt.DebtRecord?> getDebtById(String id) async {
    final repo = _driftDebtRepository;
    if (repo != null) {
      return repo.getById(id);
    }
    return null;
  }

  Future<void> saveGroceryTemplate(String name, List<String> items) async {
    final repo = _driftGroceryTemplateRepository;
    if (repo != null) {
      final template = wm_template.GroceryTemplate(
        id: const Uuid().v4(),
        name: name,
        items: items,
        createdAt: DateTime.now().toIso8601String(),
      );
      await repo.create(template);
      await refresh();
    }
  }

  Future<void> updateGroceryTemplate(wm_template.GroceryTemplate template) async {
    final repo = _driftGroceryTemplateRepository;
    if (repo != null) {
      await repo.update(template);
      await refresh();
    }
  }

  Future<void> deleteGroceryTemplate(String id) async {
    final repo = _driftGroceryTemplateRepository;
    if (repo != null) {
      await repo.delete(id);
      await refresh();
    }
  }

  Future<void> softDeleteExpense(String id) async {
    await _softDeleteExpense(id);
    await refresh();
  }

  Future<void> restoreExpense(String id) async {
    await _restoreExpense(id);
    await refresh();
  }

  Future<void> permanentlyDeleteExpense(String id) async {
    final expense = await _getExpenseById(id, includeDeleted: true);
    await _permanentlyDeleteExpense(id);
    final receipt = expense?.receiptImageUri;
    if (receipt != null) {
      await receiptStorage.delete(receipt);
    }
    await refresh();
  }

  Future<void> setBudget(String categoryId, double amount) async {
    await _upsertBudget(
      categoryId: categoryId,
      amount: amount,
      currency: settings.currency,
      month: currentMonthKey,
    );
    await refresh();
  }

  Future<void> clearBudget(String categoryId) async {
    await _deleteBudget(categoryId, currentMonthKey);
    await refresh();
  }

  Future<void> previousMonth() async {
    _clearCache();
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    currentBudgets = await _listBudgetsForMonth(currentMonthKey);
    _updateCurrentMonthExpenses();
    notifyListeners();
  }

  Future<void> nextMonth() async {
    _clearCache();
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    currentBudgets = await _listBudgetsForMonth(currentMonthKey);
    _updateCurrentMonthExpenses();
    notifyListeners();
  }

  wm.Category? categoryById(String id) {
    _categoryMap ??= {for (final c in categories) c.id: c};
    return _categoryMap![id];
  }

  Future<void> _initializeDriftReadRepositories() async {
    try {
      final database = await local.WalletMeltDatabase.open();
      _driftDatabase = database;
      _driftCategoryRepository = DriftCategoryRepository(database);
      _driftBudgetRepository = DriftBudgetRepository(database);
      _driftExpenseRepository = DriftExpenseRepository(database);
      _driftDebtRepository = DriftDebtRepository(database);
      _driftGroceryTemplateRepository = DriftGroceryTemplateRepository(database);
    } catch (_) {
      _driftDatabase = null;
      _driftCategoryRepository = null;
      _driftBudgetRepository = null;
      _driftExpenseRepository = null;
      _driftDebtRepository = null;
      _driftGroceryTemplateRepository = null;
    }
  }

  Future<List<wm.Category>> _listCategories() async {
    final repository = _driftCategoryRepository;
    if (repository != null) {
      try {
        return await repository.listCategories();
      } catch (_) {
        // Fall through to the proven sqflite path if the new read path fails.
      }
    }
    return _categoryRepository.listCategories();
  }

  Future<List<CategoryBudget>> _listBudgetsForMonth(String month) async {
    final repository = _driftBudgetRepository;
    if (repository != null) {
      try {
        return await repository.listForMonth(month);
      } catch (_) {
        // Fall through to the proven sqflite path if the new read path fails.
      }
    }
    return _budgetRepository.listForMonth(month);
  }

  Future<void> _upsertBudget({
    required String categoryId,
    required double amount,
    required String currency,
    required String month,
  }) async {
    final repository = _driftBudgetRepository;
    if (repository != null) {
      try {
        await repository.upsert(
          categoryId: categoryId,
          amount: amount,
          currency: currency,
          month: month,
        );
        return;
      } catch (_) {
        // Fall through to the proven sqflite path if the new write path fails.
      }
    }
    await _budgetRepository.upsert(
      categoryId: categoryId,
      amount: amount,
      currency: currency,
      month: month,
    );
  }

  Future<void> _deleteBudget(String categoryId, String month) async {
    final repository = _driftBudgetRepository;
    if (repository != null) {
      try {
        await repository.delete(categoryId, month);
        return;
      } catch (_) {
        // Fall through to the proven sqflite path if the new write path fails.
      }
    }
    await _budgetRepository.delete(categoryId, month);
  }

  Future<List<Expense>> _listActiveExpenses() async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        return await repository.listActive();
      } catch (_) {
        // Fall through to the proven sqflite path if the new read path fails.
      }
    }
    return _expenseRepository.listActive();
  }

  Future<List<Expense>> _listDeletedExpenses() async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        return await repository.listDeleted();
      } catch (_) {
        // Fall through to the proven sqflite path if the new read path fails.
      }
    }
    return _expenseRepository.listDeleted();
  }

  Future<Expense?> _getExpenseById(String id,
      {bool includeDeleted = false}) async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        return await repository.getById(id, includeDeleted: includeDeleted);
      } catch (_) {
        // Fall through to the proven sqflite path if the new read path fails.
      }
    }
    return _expenseRepository.getById(id, includeDeleted: includeDeleted);
  }

  Future<void> _softDeleteExpense(String id) async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        await repository.softDelete(id);
        return;
      } catch (_) {
        // Fall through to the proven sqflite path.
      }
    }
    await _expenseRepository.softDelete(id);
  }

  Future<void> _restoreExpense(String id) async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        await repository.restore(id);
        return;
      } catch (_) {
        // Fall through to the proven sqflite path.
      }
    }
    await _expenseRepository.restore(id);
  }

  Future<void> _permanentlyDeleteExpense(String id) async {
    final repository = _driftExpenseRepository;
    if (repository != null) {
      try {
        await repository.permanentlyDelete(id);
        return;
      } catch (_) {
        // Fall through to the proven sqflite path.
      }
    }
    await _expenseRepository.permanentlyDelete(id);
  }

  @override
  void dispose() {
    // Do NOT close _driftDatabase here. WalletMeltDatabase.open() returns a
    // singleton shared with Riverpod's walletMeltDatabaseProvider. The
    // provider's ref.onDispose(database.close) owns the teardown lifecycle.
    super.dispose();
  }
}
