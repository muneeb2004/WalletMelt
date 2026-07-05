import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:drift/native.dart';
import '../data/local/wallet_melt_database.dart' as local;
import '../data/repositories/drift/drift_budget_repository.dart';
import '../data/repositories/drift/drift_category_repository.dart';
import '../data/repositories/drift/drift_expense_repository.dart';
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
import '../types/subscription.dart' as wm_sub;
import '../types/subscription.dart' show SubscriptionStatus;
import '../data/repositories/drift/drift_debt_repository.dart';
import '../data/repositories/drift/drift_grocery_template_repository.dart';
import '../data/repositories/drift/drift_subscription_repository.dart';
import '../types/payee.dart';
import '../data/repositories/drift/drift_payee_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    DriftCategoryRepository? driftCategoryRepository,
    DriftBudgetRepository? driftBudgetRepository,
    DriftExpenseRepository? driftExpenseRepository,
    DriftDebtRepository? driftDebtRepository,
    DriftGroceryTemplateRepository? driftGroceryTemplateRepository,
    DriftSubscriptionRepository? driftSubscriptionRepository,
    DriftPayeeRepository? driftPayeeRepository,
    local.WalletMeltDatabase? driftDatabase,
    SettingsService? settingsService,
    ReceiptStorageService? receiptStorageService,
  })  : _driftDatabase = driftDatabase,
        _settingsService = settingsService ?? SettingsService(),
        _requiresDriftRestoreRuntime = driftDatabase != null,
        receiptStorage = receiptStorageService ?? LocalReceiptStorageService() {
    _driftCategoryRepository = driftCategoryRepository ?? _FakeDriftCategoryRepository();
    _driftBudgetRepository = driftBudgetRepository ?? _FakeDriftBudgetRepository();
    _driftExpenseRepository = driftExpenseRepository ?? _FakeDriftExpenseRepository();
    _driftDebtRepository = driftDebtRepository ?? _FakeDriftDebtRepository();
    _driftGroceryTemplateRepository = driftGroceryTemplateRepository ?? _FakeDriftGroceryTemplateRepository();
    _driftSubscriptionRepository = driftSubscriptionRepository ?? _FakeDriftSubscriptionRepository();
    _driftPayeeRepository = driftPayeeRepository ?? _FakeDriftPayeeRepository();
  }

  AppState.test({
    DriftCategoryRepository? driftCategoryRepository,
    DriftBudgetRepository? driftBudgetRepository,
    DriftExpenseRepository? driftExpenseRepository,
    DriftDebtRepository? driftDebtRepository,
    DriftGroceryTemplateRepository? driftGroceryTemplateRepository,
    DriftSubscriptionRepository? driftSubscriptionRepository,
    DriftPayeeRepository? driftPayeeRepository,
    SettingsService? settingsService,
    ReceiptStorageService? receiptStorageService,
    bool requiresDriftRestoreRuntime = false,
  })  : _settingsService = settingsService ?? SettingsService(),
        _requiresDriftRestoreRuntime = requiresDriftRestoreRuntime,
        receiptStorage = receiptStorageService ?? LocalReceiptStorageService() {
    _driftCategoryRepository = driftCategoryRepository ?? _FakeDriftCategoryRepository();
    _driftBudgetRepository = driftBudgetRepository ?? _FakeDriftBudgetRepository();
    _driftExpenseRepository = driftExpenseRepository ?? _FakeDriftExpenseRepository();
    _driftDebtRepository = driftDebtRepository ?? _FakeDriftDebtRepository();
    _driftGroceryTemplateRepository = driftGroceryTemplateRepository ?? _FakeDriftGroceryTemplateRepository();
    _driftSubscriptionRepository = driftSubscriptionRepository ?? _FakeDriftSubscriptionRepository();
    _driftPayeeRepository = driftPayeeRepository ?? _FakeDriftPayeeRepository();
    isLoading = false;
  }

  final SettingsService _settingsService;
  final ReceiptStorageService receiptStorage;
  final bool _requiresDriftRestoreRuntime;

  local.WalletMeltDatabase? _driftDatabase;
  late DriftCategoryRepository _driftCategoryRepository;
  late DriftBudgetRepository _driftBudgetRepository;
  late DriftExpenseRepository _driftExpenseRepository;
  late DriftDebtRepository _driftDebtRepository;
  late DriftGroceryTemplateRepository _driftGroceryTemplateRepository;
  late DriftSubscriptionRepository _driftSubscriptionRepository;
  late DriftPayeeRepository _driftPayeeRepository;

  List<wm_debt.DebtRecord> debts = const [];
  List<wm_template.GroceryTemplate> groceryTemplates = const [];
  List<wm_sub.Subscription> subscriptions = const [];
  List<Payee> payees = const [];

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

    await processSubscriptionRenewals();
    subscriptions = await _driftSubscriptionRepository.listAll();

    categories = await _listCategories();
    expenses = await _listActiveExpenses();
    currentBudgets = await _listBudgetsForMonth(currentMonthKey);
    _updateCurrentMonthExpenses();

    debts = await _driftDebtRepository.listAll();
    groceryTemplates = await _driftGroceryTemplateRepository.listAll();
    payees = await _driftPayeeRepository.listAll();

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
    await _driftBudgetRepository.upsert(
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
    await _driftBudgetRepository.delete(categoryId, month);
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
    final category = await _driftCategoryRepository.createCustom(
        name: name, icon: icon, color: color);
    await refresh();
    return category;
  }

  Future<Expense> addExpense(ExpenseDraft draft) async {
    final expense = await _driftExpenseRepository.create(draft);
    await refresh();
    return expense;
  }

  Future<void> updateExpense(Expense expense,
      {List<GroceryItemDraft>? groceryItems}) async {
    await _driftExpenseRepository.update(expense, groceryItems: groceryItems);
    await refresh();
  }

  Future<List<GroceryItem>> groceryItemsForExpense(String expenseId) async {
    return _driftExpenseRepository.groceryItemsForExpense(expenseId);
  }

  Future<List<GroceryItem>> listAllGroceryItemsForExport() async {
    return _driftExpenseRepository.listAllGroceryItems();
  }

  Future<List<CategoryBudget>> listAllBudgetsForExport() async {
    return _driftBudgetRepository.listAll();
  }

  Future<void> addDebt(wm_debt.DebtRecord debt) async {
    await _driftDebtRepository.createDebt(debt);
    await refresh();
  }

  Future<void> deleteDebt(String id) async {
    await _driftDebtRepository.deleteDebt(id);
    await refresh();
  }

  Future<void> addRepayment({
    required String debtId,
    required double amount,
    String? notes,
  }) async {
    final repayment = wm_debt.DebtRepayment(
      id: const Uuid().v4(),
      debtId: debtId,
      amount: amount,
      createdAt: DateTime.now().toIso8601String(),
      notes: notes,
    );
    await _driftDebtRepository.addRepayment(repayment);
    await refresh();
  }

  Future<List<wm_debt.DebtRepayment>> repaymentsForDebt(String debtId) async {
    return _driftDebtRepository.getRepayments(debtId);
  }

  Future<void> addSubscription(wm_sub.Subscription sub) async {
    await _driftSubscriptionRepository.create(sub);
    await refresh();
  }

  Future<void> updateSubscription(wm_sub.Subscription sub) async {
    await _driftSubscriptionRepository.update(sub);
    await refresh();
  }

  Future<void> deleteSubscription(String id) async {
    await _driftSubscriptionRepository.delete(id);
    await refresh();
  }

  Future<void> processSubscriptionRenewals() async {
    final subs = await _driftSubscriptionRepository.listAll();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    for (final sub in subs) {
      if (sub.status != SubscriptionStatus.active) continue;

      var currentNextDateStr = sub.nextOccurrenceDate;
      var updatedSub = sub;
      bool hasRenewals = false;

      while (currentNextDateStr.compareTo(todayStr) <= 0) {
        hasRenewals = true;
        final parsedDate = DateTime.parse(currentNextDateStr);
        
        final draft = ExpenseDraft(
          amount: sub.amount + (sub.taxAmount ?? 0.0),
          currency: sub.currency,
          categoryId: sub.categoryId,
          title: '${sub.name} (Recurring Renewal)',
          date: parsedDate,
          vendor: sub.name,
          notes: 'Auto-generated subscription renewal for ${sub.name}',
          subtotalAmount: sub.amount,
          taxAmount: sub.taxAmount,
        );

        await _driftExpenseRepository.create(draft);

        final nextDate = sub.calculateNextRenewalDate(parsedDate);
        currentNextDateStr = nextDate.toIso8601String().substring(0, 10);
        
        updatedSub = updatedSub.copyWith(
          nextOccurrenceDate: currentNextDateStr,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      if (hasRenewals) {
        await _driftSubscriptionRepository.update(updatedSub);
      }
    }
  }

  Future<wm_debt.DebtRecord?> getDebtById(String id) async {
    return _driftDebtRepository.getById(id);
  }

  Future<void> saveGroceryTemplate(String name, List<String> items) async {
    final template = wm_template.GroceryTemplate(
      id: const Uuid().v4(),
      name: name,
      items: items,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _driftGroceryTemplateRepository.create(template);
    await refresh();
  }

  Future<void> updateGroceryTemplate(wm_template.GroceryTemplate template) async {
    await _driftGroceryTemplateRepository.update(template);
    await refresh();
  }

  Future<void> deleteGroceryTemplate(String id) async {
    await _driftGroceryTemplateRepository.delete(id);
    await refresh();
  }

  Future<void> softDeleteExpense(String id) async {
    await _driftExpenseRepository.softDelete(id);
    await refresh();
  }

  Future<void> restoreExpense(String id) async {
    await _driftExpenseRepository.restore(id);
    await refresh();
  }

  Future<void> permanentlyDeleteExpense(String id) async {
    final expense = await _driftExpenseRepository.getById(id, includeDeleted: true);
    await _driftExpenseRepository.permanentlyDelete(id);
    final receipt = expense?.receiptImageUri;
    if (receipt != null) {
      await receiptStorage.delete(receipt);
    }
    await refresh();
  }

  Future<void> setBudget(String categoryId, double amount) async {
    await _driftBudgetRepository.upsert(
      categoryId: categoryId,
      amount: amount,
      currency: settings.currency,
      month: currentMonthKey,
    );
    await refresh();
  }

  Future<void> clearBudget(String categoryId) async {
    await _driftBudgetRepository.delete(categoryId, currentMonthKey);
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



  Future<List<wm.Category>> _listCategories() async {
    final rawList = await _driftCategoryRepository.listCategories();
    final list = List<wm.Category>.from(rawList);
    final otherIndex = list.indexWhere((c) => c.id == 'other' || c.name.toLowerCase() == 'other');
    if (otherIndex != -1) {
      final other = list.removeAt(otherIndex);
      list.add(other);
    }
    return list;
  }

  Future<List<CategoryBudget>> _listBudgetsForMonth(String month) async {
    return _driftBudgetRepository.listForMonth(month);
  }

  Future<List<Expense>> _listActiveExpenses() async {
    return _driftExpenseRepository.listActive();
  }

  Future<List<Expense>> _listDeletedExpenses() async {
    return _driftExpenseRepository.listDeleted();
  }

  String payeeNameFor(wm_debt.DebtRecord debt) {
    if (debt.payeeId != null) {
      final payee = payees.firstWhereOrNull((p) => p.id == debt.payeeId);
      if (payee != null) return payee.name;
    }
    return debt.personName;
  }

  Future<void> addPayee(Payee payee) async {
    await _driftPayeeRepository.create(payee);
    await refresh();
  }

  Future<void> updatePayee(Payee payee) async {
    await _driftPayeeRepository.update(payee);
    await refresh();
  }

  Future<void> deletePayee(String id) async {
    await _driftPayeeRepository.delete(id);
    await refresh();
  }

  Future<void> mergePayees({required String keepId, required String duplicateId}) async {
    await _driftPayeeRepository.merge(keepId: keepId, duplicateId: duplicateId);
    await refresh();
  }


}

class _FakeDriftCategoryRepository extends DriftCategoryRepository {
  _FakeDriftCategoryRepository() : super(_dummyDb);
  @override
  Future<List<wm.Category>> listCategories() async => [];
}

class _FakeDriftBudgetRepository extends DriftBudgetRepository {
  _FakeDriftBudgetRepository() : super(_dummyDb);
  @override
  Future<List<CategoryBudget>> listForMonth(String month) async => [];
}

class _FakeDriftExpenseRepository extends DriftExpenseRepository {
  _FakeDriftExpenseRepository() : super(_dummyDb);
  @override
  Future<List<Expense>> listActive() async => [];
}

class _FakeDriftDebtRepository extends DriftDebtRepository {
  _FakeDriftDebtRepository() : super(_dummyDb);
  @override
  Future<List<wm_debt.DebtRecord>> listAll() async => [];
}

class _FakeDriftGroceryTemplateRepository extends DriftGroceryTemplateRepository {
  _FakeDriftGroceryTemplateRepository() : super(_dummyDb);
  @override
  Future<List<wm_template.GroceryTemplate>> listAll() async => [];
}

class _FakeDriftSubscriptionRepository extends DriftSubscriptionRepository {
  _FakeDriftSubscriptionRepository() : super(_dummyDb);
  @override
  Future<List<wm_sub.Subscription>> listAll() async => [];
}

class _FakeDriftPayeeRepository extends DriftPayeeRepository {
  _FakeDriftPayeeRepository() : super(_dummyDb);
}

final _dummyDb = local.WalletMeltDatabase(NativeDatabase.memory());
