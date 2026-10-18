import '../services/export/wallet_melt_json_backup_extended_tables.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
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
import '../types/insight_card.dart';
import '../types/settings.dart';
import '../types/spending_summaries.dart';
import '../utils/date_utils.dart';
import '../utils/insights.dart';
import '../analytics/analytics_snapshot.dart';
import '../analytics/insight_engine.dart';
import '../analytics/spending_analytics.dart';
import '../analytics/summary_builder.dart';

import 'package:uuid/uuid.dart';
import '../types/debt.dart' as wm_debt;
import '../types/grocery_template.dart' as wm_template;
import '../types/subscription.dart' as wm_sub;
import '../types/subscription.dart' show SubscriptionStatus;
import '../types/essential_expense.dart' as wm_essential;
import '../types/fuel.dart' as wm_fuel;
import '../data/repositories/drift/drift_debt_repository.dart';
import '../data/repositories/drift/drift_grocery_template_repository.dart';
import '../data/repositories/drift/drift_subscription_repository.dart';
import '../types/payee.dart';
import '../data/repositories/drift/drift_payee_repository.dart';
import '../data/repositories/drift/drift_essential_expense_repository.dart';
import '../data/repositories/drift/drift_fuel_repository.dart';
import '../types/merchant.dart';
import '../data/repositories/drift/drift_store_repository.dart';
import '../data/repositories/drift/drift_monthly_budget_repository.dart';
import '../types/monthly_budget.dart';
import '../analytics/balance_calculator.dart';
import '../utils/budget_period.dart';
import '../analytics/committee_planner.dart';
import '../analytics/goal_planner.dart';
import '../data/repositories/drift/drift_committee_repository.dart';
import '../types/committee.dart' as wm_committee;
import '../analytics/income_planner.dart';
import '../data/repositories/drift/drift_goal_repository.dart';
import '../types/savings_goal.dart' as wm_goal;
import '../data/repositories/drift/drift_income_repository.dart';
import '../types/income.dart' as wm_income;
import '../data/repositories/drift/drift_account_repository.dart';
import '../types/account.dart' as wm_account;

class AppState extends ChangeNotifier {
  AppState({
    DriftCategoryRepository? driftCategoryRepository,
    DriftBudgetRepository? driftBudgetRepository,
    DriftMonthlyBudgetRepository? driftMonthlyBudgetRepository,
    DriftExpenseRepository? driftExpenseRepository,
    DriftDebtRepository? driftDebtRepository,
    DriftGroceryTemplateRepository? driftGroceryTemplateRepository,
    DriftSubscriptionRepository? driftSubscriptionRepository,
    DriftPayeeRepository? driftPayeeRepository,
    DriftEssentialExpenseRepository? driftEssentialExpenseRepository,
    DriftFuelRepository? driftFuelRepository,
    DriftStoreRepository? driftStoreRepository,
    DriftAccountRepository? driftAccountRepository,
    DriftIncomeRepository? driftIncomeRepository,
    DriftGoalRepository? driftGoalRepository,
    DriftCommitteeRepository? driftCommitteeRepository,
    local.WalletMeltDatabase? driftDatabase,
    SettingsService? settingsService,
    ReceiptStorageService? receiptStorageService,
  })  : _driftDatabase = driftDatabase,
        _settingsService = settingsService ?? SettingsService(),
        _requiresDriftRestoreRuntime = driftDatabase != null,
        receiptStorage = receiptStorageService ?? LocalReceiptStorageService() {
    _driftCategoryRepository = driftCategoryRepository ?? _FakeDriftCategoryRepository();
    _driftBudgetRepository = driftBudgetRepository ?? _FakeDriftBudgetRepository();
    _driftMonthlyBudgetRepository = driftMonthlyBudgetRepository ??
        (driftDatabase != null
            ? DriftMonthlyBudgetRepository(driftDatabase)
            : _FakeDriftMonthlyBudgetRepository());
    _driftExpenseRepository = driftExpenseRepository ?? _FakeDriftExpenseRepository();
    _driftDebtRepository = driftDebtRepository ?? _FakeDriftDebtRepository();
    _driftGroceryTemplateRepository = driftGroceryTemplateRepository ?? _FakeDriftGroceryTemplateRepository();
    _driftSubscriptionRepository = driftSubscriptionRepository ?? _FakeDriftSubscriptionRepository();
    _driftPayeeRepository = driftPayeeRepository ?? _FakeDriftPayeeRepository();
    _driftEssentialExpenseRepository = driftEssentialExpenseRepository ?? _FakeDriftEssentialExpenseRepository();
    _driftFuelRepository = driftFuelRepository ?? _FakeDriftFuelRepository();
    _driftStoreRepository = driftStoreRepository ?? (driftDatabase != null ? DriftStoreRepository(driftDatabase) : _FakeDriftStoreRepository());
    _accountRepository = driftAccountRepository ??
        (driftDatabase != null ? DriftAccountRepository(driftDatabase) : null);
    _incomeRepository = driftIncomeRepository ??
        (driftDatabase != null ? DriftIncomeRepository(driftDatabase) : null);
    _goalRepository = driftGoalRepository ??
        (driftDatabase != null ? DriftGoalRepository(driftDatabase) : null);
    _committeeRepository = driftCommitteeRepository ??
        (driftDatabase != null ? DriftCommitteeRepository(driftDatabase) : null);
  }

  AppState.test({
    DriftCategoryRepository? driftCategoryRepository,
    DriftBudgetRepository? driftBudgetRepository,
    DriftMonthlyBudgetRepository? driftMonthlyBudgetRepository,
    DriftExpenseRepository? driftExpenseRepository,
    DriftDebtRepository? driftDebtRepository,
    DriftGroceryTemplateRepository? driftGroceryTemplateRepository,
    DriftSubscriptionRepository? driftSubscriptionRepository,
    DriftPayeeRepository? driftPayeeRepository,
    DriftEssentialExpenseRepository? driftEssentialExpenseRepository,
    DriftFuelRepository? driftFuelRepository,
    DriftStoreRepository? driftStoreRepository,
    DriftAccountRepository? driftAccountRepository,
    DriftIncomeRepository? driftIncomeRepository,
    DriftGoalRepository? driftGoalRepository,
    DriftCommitteeRepository? driftCommitteeRepository,
    SettingsService? settingsService,
    ReceiptStorageService? receiptStorageService,
    WalletMeltSettings? settings,
    bool requiresDriftRestoreRuntime = false,
  })  : _settingsService = settingsService ?? SettingsService(),
        _requiresDriftRestoreRuntime = requiresDriftRestoreRuntime,
        receiptStorage = receiptStorageService ?? LocalReceiptStorageService() {
    this.settings = settings ??
        WalletMeltSettings.defaults.copyWith(
          hasAcceptedPrivacyPolicy: true,
          hasCompletedOnboarding: true,
        );
    _driftCategoryRepository = driftCategoryRepository ?? _FakeDriftCategoryRepository();

    _driftBudgetRepository = driftBudgetRepository ?? _FakeDriftBudgetRepository();
    _driftMonthlyBudgetRepository =
        driftMonthlyBudgetRepository ?? _FakeDriftMonthlyBudgetRepository();
    _driftExpenseRepository = driftExpenseRepository ?? _FakeDriftExpenseRepository();
    _driftDebtRepository = driftDebtRepository ?? _FakeDriftDebtRepository();
    _driftGroceryTemplateRepository = driftGroceryTemplateRepository ?? _FakeDriftGroceryTemplateRepository();
    _driftSubscriptionRepository = driftSubscriptionRepository ?? _FakeDriftSubscriptionRepository();
    _driftPayeeRepository = driftPayeeRepository ?? _FakeDriftPayeeRepository();
    _driftEssentialExpenseRepository = driftEssentialExpenseRepository ?? _FakeDriftEssentialExpenseRepository();
    _driftFuelRepository = driftFuelRepository ?? _FakeDriftFuelRepository();
    _driftStoreRepository = driftStoreRepository ?? _FakeDriftStoreRepository();
    _accountRepository = driftAccountRepository;
    _incomeRepository = driftIncomeRepository;
    _goalRepository = driftGoalRepository;
    _committeeRepository = driftCommitteeRepository;
    isLoading = false;
  }

  final SettingsService _settingsService;
  final ReceiptStorageService receiptStorage;
  final bool _requiresDriftRestoreRuntime;

  local.WalletMeltDatabase? _driftDatabase;
  late DriftCategoryRepository _driftCategoryRepository;
  late DriftBudgetRepository _driftBudgetRepository;
  late DriftMonthlyBudgetRepository _driftMonthlyBudgetRepository;
  late DriftExpenseRepository _driftExpenseRepository;
  late DriftDebtRepository _driftDebtRepository;
  late DriftGroceryTemplateRepository _driftGroceryTemplateRepository;
  late DriftSubscriptionRepository _driftSubscriptionRepository;
  late DriftPayeeRepository _driftPayeeRepository;
  late DriftEssentialExpenseRepository _driftEssentialExpenseRepository;
  late DriftFuelRepository _driftFuelRepository;
  late DriftStoreRepository _driftStoreRepository;
  DriftAccountRepository? _accountRepository;
  DriftIncomeRepository? _incomeRepository;
  DriftGoalRepository? _goalRepository;
  DriftCommitteeRepository? _committeeRepository;

  /// Committees need the Drift runtime like accounts (ADR-0016).
  bool get committeesAvailable => _committeeRepository != null;
  List<wm_committee.CommitteeProgress> committeeProgress = const [];

  /// Installments and payouts due today or earlier, oldest first.
  List<CommitteeDueItem> get dueCommitteeItems =>
      CommitteePlanner.dueItems(committeeProgress, DateTime.now());

  /// Savings goals need the Drift runtime like accounts (ADR-0015).
  bool get goalsAvailable => _goalRepository != null;
  List<wm_goal.GoalProgress> goalProgress = const [];

  /// Money set aside per account by active goals.
  Map<String, int> get reservedByAccount =>
      GoalPlanner.reservedByAccount(goalProgress);

  /// Balance minus set-aside money for one account (may be negative).
  int freeToSpendFor(String accountId) {
    final balance = accountBalances
        .where((b) => b.account.id == accountId)
        .map((b) => b.balanceMinorUnits)
        .firstOrNull;
    if (balance == null) return 0;
    return GoalPlanner.freeToSpend(balance, reservedByAccount[accountId] ?? 0);
  }

  /// Free-to-spend per currency over accounts included in the total.
  List<wm_account.CurrencyTotal> get freeToSpendTotals =>
      GoalPlanner.freeTotalsByCurrency(accountBalances, reservedByAccount);

  /// Income needs the Drift runtime like accounts (ADR-0012).
  bool get incomeAvailable => _incomeRepository != null;
  List<wm_income.Income> incomes = const [];
  List<wm_income.IncomeSchedule> incomeSchedules = const [];

  /// Active schedules whose next occurrence is today or earlier.
  List<wm_income.IncomeSchedule> get dueIncomeSchedules {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (final s in incomeSchedules)
        if (s.isActive &&
            (DateTime.tryParse(s.nextDueDate)?.compareTo(today) ?? 1) <= 0)
          s,
    ];
  }

  /// Expected income this calendar month in the app currency, minor units.
  int get expectedIncomeThisMonthMinorUnits => IncomePlanner.expectedForMonth(
        month: budgetPeriod.periodOf(DateTime.now()),
        currency: settings.currency,
        received: incomes,
        schedules: incomeSchedules,
        period: budgetPeriod,
      );

  /// Advisory budget (major units) from expected income minus commitments, or
  /// null when no income is expected. Never applied automatically.
  double? get suggestedMonthlyBudget => IncomePlanner.suggestedBudget(
        expectedIncomeMinorUnits: expectedIncomeThisMonthMinorUnits,
        subscriptions: subscriptions,
        essentials: essentialTemplates,
      );

  /// Accounts need the Drift runtime; the legacy fallback has none (ADR-0011).
  bool get accountsAvailable => _accountRepository != null;
  List<wm_account.AccountBalance> accountBalances = const [];
  int unassignedExpenseCount = 0;

  List<wm_account.Account> get accounts =>
      [for (final b in accountBalances) b.account];

  List<wm_account.CurrencyTotal> get accountTotals =>
      BalanceCalculator.totalsByCurrency(accountBalances);

  MonthlyBudget? _currentMonthlyBudget;
  final Map<String, MonthlyBudget?> _monthlyBudgetCache = {};

  List<wm_debt.DebtRecord> debts = const [];
  List<wm_template.GroceryTemplate> groceryTemplates = const [];
  List<wm_sub.Subscription> subscriptions = const [];
  List<Payee> payees = const [];
  List<wm_essential.EssentialExpenseTemplate> essentialTemplates = const [];
  List<Merchant> savedMerchants = const [];

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

  /// Budget period definition from settings (ADR-0013). Start day 1 is the
  /// calendar month.
  BudgetPeriod get budgetPeriod =>
      BudgetPeriod.fromStartDay(settings.budgetPeriodStartDay);
  DateTime get selectedMonth => _selectedMonth;
  set selectedMonth(DateTime value) {
    _selectedMonth = value;
    _updateCurrentMonthExpenses();
  }
  bool isLoading = true;
  String? errorMessage;
  bool isOffline = false;

  double? _cachedTotalSpent;
  MonthlyInsights? _cachedInsights;

  SpendingAnalyticsSnapshot? _cachedSnapshot;
  DateTime? _cachedSnapshotDay;
  int _analyticsGeneration = 0;
  int? _cachedSnapshotGeneration;

  List<InsightCard>? _cachedInsightCards;
  int? _cachedInsightCardsGeneration;

  SpendingSummaries? _cachedSummaries;
  int? _cachedSummariesGeneration;

  List<Expense> _currentMonthExpenses = const [];
  List<Expense> get currentMonthExpenses {
    if (_currentMonthExpenses.isEmpty && expenses.isNotEmpty) {
      _updateCurrentMonthExpenses();
    }
    return _currentMonthExpenses;
  }

  Map<String, wm.Category>? _categoryMap;

  void _clearAnalyticsCache() {
    _analyticsGeneration++;
    _cachedSnapshot = null;
    _cachedSnapshotDay = null;
    _cachedSnapshotGeneration = null;
    _cachedInsightCards = null;
    _cachedInsightCardsGeneration = null;
    _cachedSummaries = null;
    _cachedSummariesGeneration = null;
  }

  void _clearCache() {
    _cachedTotalSpent = null;
    _cachedInsights = null;
    _categoryMap = null;
    _clearAnalyticsCache();
  }

  void _updateCurrentMonthExpenses() {
    _clearCache();
    _currentMonthExpenses = expenses.where((e) {
      if (e.deletedAt != null) return false;
      try {
        return budgetPeriod.contains(selectedMonth, parseIsoDate(e.date));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  String get currentMonthKey => monthKey(selectedMonth);

  /// Single source of truth analytics snapshot for the selected month.
  SpendingAnalyticsSnapshot get spendingSnapshot {
    final now = DateTime.now();
    if (_cachedSnapshot != null &&
        _cachedSnapshotGeneration == _analyticsGeneration &&
        _cachedSnapshotDay != null &&
        _cachedSnapshotDay!.year == now.year &&
        _cachedSnapshotDay!.month == now.month &&
        _cachedSnapshotDay!.day == now.day) {
      return _cachedSnapshot!;
    }
    _clearAnalyticsCache();
    _cachedSnapshotDay = now;
    _cachedSnapshotGeneration = _analyticsGeneration;
    _cachedSnapshot = SpendingAnalytics.buildSnapshot(
      expenses: expenses,
      selectedMonth: selectedMonth,
      now: now,
      currency: settings.currency,
      period: budgetPeriod,
    );
    return _cachedSnapshot!;
  }

  /// Ranked actionable insight cards for the selected month.
  List<InsightCard> get insightCards {
    final snap = spendingSnapshot;
    if (_cachedInsightCards != null &&
        _cachedInsightCardsGeneration == _analyticsGeneration) {
      return _cachedInsightCards!;
    }
    _cachedInsightCardsGeneration = _analyticsGeneration;
    _cachedInsightCards = InsightEngine.generate(
      snapshot: snap,
      categories: categories,
      budgets: currentBudgets,
      essentialTemplates: essentialTemplates,
      subscriptions: subscriptions,
      monthlyBudgetAmount: getMonthlyBudgetAmount(currentMonthKey),
    );
    return _cachedInsightCards!;
  }

  /// Dedicated analytical spending summaries for the selected month.
  SpendingSummaries get spendingSummaries {
    final snap = spendingSnapshot;
    if (_cachedSummaries != null &&
        _cachedSummariesGeneration == _analyticsGeneration) {
      return _cachedSummaries!;
    }
    _cachedSummariesGeneration = _analyticsGeneration;
    _cachedSummaries = SummaryBuilder.build(
      snapshot: snap,
      categories: categories,
    );
    return _cachedSummaries!;
  }

  MonthlyInsights get monthlyInsights {
    if (_cachedInsights != null) return _cachedInsights!;
    _cachedInsights = buildMonthlyInsightsFromSnapshot(
      snapshot: spendingSnapshot,
      categories: categories,
      budgets: currentBudgets,
    );
    return _cachedInsights!;
  }

  Future<void> initialize() async {
    try {
      isLoading = true;
      notifyListeners();
      settings = await _settingsService.load();
      _selectedMonth = budgetPeriod.periodOf(DateTime.now());
      await refresh();
    } catch (error, stack) {
      debugPrint('AppState.initialize error: $error\n$stack');
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
    _currentMonthlyBudget = await _driftMonthlyBudgetRepository.getForMonth(currentMonthKey);
    _monthlyBudgetCache[currentMonthKey] = _currentMonthlyBudget;
    _updateCurrentMonthExpenses();

    debts = await _driftDebtRepository.listAll();
    groceryTemplates = await _driftGroceryTemplateRepository.listAll();
    payees = await _driftPayeeRepository.listAll();
    essentialTemplates = await _driftEssentialExpenseRepository.listAll();
    savedMerchants = await _driftStoreRepository.listSavedMerchants();
    await _refreshAccounts();
    await _refreshIncome();
    await _refreshGoals();
    await _refreshCommittees();

    notifyListeners();
  }

  Future<void> _refreshCommittees() async {
    final repo = _committeeRepository;
    committeeProgress = repo == null ? const [] : await repo.listProgress();
  }

  Future<void> _refreshGoals() async {
    final repo = _goalRepository;
    goalProgress = repo == null ? const [] : await repo.listProgress();
  }

  Future<void> _refreshIncome() async {
    final repo = _incomeRepository;
    if (repo == null) {
      incomes = const [];
      incomeSchedules = const [];
      return;
    }
    incomes = await repo.listIncomes();
    incomeSchedules = await repo.listSchedules();
  }

  Future<void> _refreshAccounts() async {
    final repo = _accountRepository;
    if (repo == null) {
      accountBalances = const [];
      unassignedExpenseCount = 0;
      return;
    }
    accountBalances = await repo.listBalances(includeArchived: true);
    unassignedExpenseCount =
        accountBalances.isEmpty ? 0 : await repo.countUnassignedExpenses();
  }

  DriftAccountRepository get _accountsOrThrow {
    final repo = _accountRepository;
    if (repo == null) {
      throw StateError('Accounts are unavailable on this storage backend.');
    }
    return repo;
  }

  Future<wm_account.Account> createAccount({
    required String name,
    required wm_account.AccountType type,
    required String currency,
    int openingBalanceMinorUnits = 0,
    DateTime? openingDate,
    bool includeInTotal = true,
  }) async {
    final account = await _accountsOrThrow.create(
      name: name,
      type: type,
      currency: currency,
      openingBalanceMinorUnits: openingBalanceMinorUnits,
      openingDate: openingDate,
      includeInTotal: includeInTotal,
    );
    await _refreshAccounts();
    notifyListeners();
    return account;
  }

  DriftIncomeRepository get _incomeOrThrow {
    final repo = _incomeRepository;
    if (repo == null) {
      throw StateError('Income is unavailable on this storage backend.');
    }
    return repo;
  }

  Future<void> _afterIncomeChange() async {
    await _refreshIncome();
    await _refreshAccounts();
    notifyListeners();
  }

  Future<wm_income.Income> addIncome({
    required String title,
    required wm_income.IncomeSource source,
    required int amountMinorUnits,
    required DateTime date,
    String? accountId,
    String? notes,
  }) async {
    final income = await _incomeOrThrow.addIncome(
      title: title,
      source: source,
      amountMinorUnits: amountMinorUnits,
      currency: settings.currency,
      date: date,
      accountId: accountId,
      notes: notes,
    );
    await _afterIncomeChange();
    return income;
  }

  Future<void> deleteIncome(String id) async {
    await _incomeOrThrow.softDeleteIncome(id);
    await _afterIncomeChange();
  }

  Future<wm_income.IncomeSchedule> createIncomeSchedule({
    required String title,
    required wm_income.IncomeSource source,
    required int amountMinorUnits,
    required String cycle,
    required DateTime firstDueDate,
    String? accountId,
  }) async {
    final schedule = await _incomeOrThrow.createSchedule(
      title: title,
      source: source,
      amountMinorUnits: amountMinorUnits,
      currency: settings.currency,
      cycle: cycle,
      firstDueDate: firstDueDate,
      accountId: accountId,
    );
    await _afterIncomeChange();
    return schedule;
  }

  Future<void> setIncomeScheduleStatus(
      String id, wm_income.IncomeScheduleStatus status) async {
    await _incomeOrThrow.setScheduleStatus(id, status);
    await _afterIncomeChange();
  }

  Future<void> deleteIncomeSchedule(String id) async {
    await _incomeOrThrow.deleteSchedule(id);
    await _afterIncomeChange();
  }

  Future<void> confirmIncomeReceived(String scheduleId,
      {int? amountMinorUnits, DateTime? receivedOn}) async {
    await _incomeOrThrow.confirmReceived(scheduleId,
        amountMinorUnits: amountMinorUnits, receivedOn: receivedOn);
    await _afterIncomeChange();
  }

  Future<void> skipIncomeOccurrence(String scheduleId) async {
    await _incomeOrThrow.skipOccurrence(scheduleId);
    await _afterIncomeChange();
  }

  DriftGoalRepository get _goalsOrThrow {
    final repo = _goalRepository;
    if (repo == null) {
      throw StateError('Savings goals are unavailable on this storage backend.');
    }
    return repo;
  }

  Future<void> _afterGoalChange() async {
    await _refreshGoals();
    notifyListeners();
  }

  Future<wm_goal.SavingsGoal> createGoal({
    required String name,
    required int targetMinorUnits,
    required String accountId,
    DateTime? targetDate,
  }) async {
    final goal = await _goalsOrThrow.createGoal(
      name: name,
      targetMinorUnits: targetMinorUnits,
      accountId: accountId,
      targetDate: targetDate,
    );
    await _afterGoalChange();
    return goal;
  }

  Future<void> setAsideForGoal(String goalId, int amountMinorUnits,
      {String? notes}) async {
    await _goalsOrThrow.setAside(goalId, amountMinorUnits, notes: notes);
    await _afterGoalChange();
  }

  Future<void> releaseFromGoal(String goalId, int amountMinorUnits) async {
    await _goalsOrThrow.release(goalId, amountMinorUnits);
    await _afterGoalChange();
  }

  Future<void> markGoalAchieved(String goalId) async {
    await _goalsOrThrow.markAchieved(goalId);
    await _afterGoalChange();
  }

  Future<void> archiveGoal(String goalId) async {
    await _goalsOrThrow.archive(goalId);
    await _afterGoalChange();
  }

  Future<void> reopenGoal(String goalId) async {
    await _goalsOrThrow.reopen(goalId);
    await _afterGoalChange();
  }

  Future<void> deleteGoal(String goalId) async {
    await _goalsOrThrow.deleteGoal(goalId);
    await _afterGoalChange();
  }

  Future<List<wm_goal.GoalContribution>> goalContributions(String goalId) =>
      _goalsOrThrow.listContributions(goalId);

  DriftCommitteeRepository get _committeesOrThrow {
    final repo = _committeeRepository;
    if (repo == null) {
      throw StateError('Committees are unavailable on this storage backend.');
    }
    return repo;
  }

  /// Committee changes can move an account balance, so balances refresh too.
  Future<void> _afterCommitteeChange() async {
    await _refreshCommittees();
    await _refreshAccounts();
    notifyListeners();
  }

  Future<wm_committee.Committee> createCommittee({
    required String name,
    required int monthlyMinorUnits,
    required int memberCount,
    required int payoutMonth,
    required DateTime startDate,
    int? payoutMinorUnits,
    String? accountId,
  }) async {
    final committee = await _committeesOrThrow.create(
      name: name,
      monthlyMinorUnits: monthlyMinorUnits,
      memberCount: memberCount,
      payoutMonth: payoutMonth,
      startDate: startDate,
      currency: settings.currency,
      payoutMinorUnits: payoutMinorUnits,
      accountId: accountId,
    );
    await _afterCommitteeChange();
    return committee;
  }

  Future<void> recordCommitteeInstallment(String committeeId, int monthIndex,
      {int? amountMinorUnits}) async {
    await _committeesOrThrow.recordInstallment(committeeId, monthIndex,
        amountMinorUnits: amountMinorUnits);
    await _afterCommitteeChange();
  }

  Future<void> recordCommitteePayout(String committeeId,
      {int? amountMinorUnits}) async {
    await _committeesOrThrow.recordPayout(committeeId,
        amountMinorUnits: amountMinorUnits);
    await _afterCommitteeChange();
  }

  Future<void> undoCommitteeEvent(String eventId) async {
    await _committeesOrThrow.undoEvent(eventId);
    await _afterCommitteeChange();
  }

  Future<void> setCommitteeAccount(String committeeId, String? accountId) async {
    await _committeesOrThrow.setAccount(committeeId, accountId);
    await _afterCommitteeChange();
  }

  Future<void> archiveCommittee(String committeeId) async {
    await _committeesOrThrow.archive(committeeId);
    await _afterCommitteeChange();
  }

  Future<void> reopenCommittee(String committeeId) async {
    await _committeesOrThrow.reopen(committeeId);
    await _afterCommitteeChange();
  }

  Future<void> deleteCommittee(String committeeId) async {
    await _committeesOrThrow.delete(committeeId);
    await _afterCommitteeChange();
  }

  Future<bool> accountHasTransactions(String id) =>
      _accountsOrThrow.hasLinkedRows(id);

  Future<void> updateAccount(wm_account.Account account) async {
    await _accountsOrThrow.update(account);
    await _refreshAccounts();
    notifyListeners();
  }

  /// Returns true when the account was deleted, false when archived.
  Future<bool> deleteOrArchiveAccount(String id) async {
    final deleted = await _accountsOrThrow.deleteOrArchive(id);
    await _refreshAccounts();
    notifyListeners();
    return deleted;
  }

  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinorUnits,
    int? receivedMinorUnits,
    DateTime? date,
    String? notes,
  }) async {
    await _accountsOrThrow.transfer(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amountMinorUnits: amountMinorUnits,
      receivedMinorUnits: receivedMinorUnits,
      date: date,
      notes: notes,
    );
    await _refreshAccounts();
    notifyListeners();
  }

  Future<void> reconcileAccount(String accountId, int actualMinorUnits) async {
    await _accountsOrThrow.reconcile(accountId, actualMinorUnits);
    await _refreshAccounts();
    notifyListeners();
  }

  /// Adds ([amountMinorUnits] > 0) or removes (< 0) money from an account as
  /// a deletable adjustment. This is not an expense and does not touch budgets.
  Future<void> adjustAccountBalance(String accountId, int amountMinorUnits,
      {String? notes}) async {
    await _accountsOrThrow.recordAdjustment(accountId, amountMinorUnits,
        notes: notes);
    await _refreshAccounts();
    notifyListeners();
  }

  Future<int> assignUnassignedExpensesTo(String accountId) async {
    final changed = await _accountsOrThrow.assignUnassignedExpenses(accountId);
    await refresh();
    return changed;
  }

  Future<List<wm_account.AccountMovement>> accountMovements(
          String accountId) =>
      _accountsOrThrow.listMovements(accountId);

  Future<void> deleteAccountMovement(String movementId) async {
    await _accountsOrThrow.deleteMovement(movementId);
    await _refreshAccounts();
    notifyListeners();
  }

  Future<void> acceptPrivacyPolicy() async {
    settings = settings.copyWith(hasAcceptedPrivacyPolicy: true);
    await _settingsService.save(settings);
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

  Future<void> updateLastSeenWhatsNewVersion(String version) async {
    settings = settings.copyWith(lastSeenWhatsNewVersion: version);
    await _settingsService.save(settings);
    notifyListeners();
  }

  double? getMonthlyBudgetAmount([String? month]) {
    final key = month ?? currentMonthKey;
    if (key == currentMonthKey && _currentMonthlyBudget != null) {
      return _currentMonthlyBudget!.amount;
    }
    if (_monthlyBudgetCache.containsKey(key) && _monthlyBudgetCache[key] != null) {
      return _monthlyBudgetCache[key]!.amount;
    }
    return settings.monthlyBudgetAmount;
  }

  Future<MonthlyBudget?> getMonthlyBudgetForMonth(String month) async {
    if (_monthlyBudgetCache.containsKey(month)) {
      return _monthlyBudgetCache[month];
    }
    final budget = await _driftMonthlyBudgetRepository.getForMonth(month);
    _monthlyBudgetCache[month] = budget;
    return budget;
  }

  Future<void> setMonthlyBudgetAmount(double amount, {String? month}) async {
    final key = month ?? currentMonthKey;
    _clearCache();
    _clearAnalyticsCache();
    await _driftMonthlyBudgetRepository.upsert(
      month: key,
      amount: amount,
      currency: settings.currency,
    );
    // Keep settings updated as latest default
    settings = settings.copyWith(monthlyBudgetAmount: amount);
    await _settingsService.save(settings);

    _currentMonthlyBudget = await _driftMonthlyBudgetRepository.getForMonth(currentMonthKey);
    _monthlyBudgetCache[key] = await _driftMonthlyBudgetRepository.getForMonth(key);
    _monthlyBudgetCache[currentMonthKey] = _currentMonthlyBudget;
    notifyListeners();
  }

  Future<void> clearMonthlyBudgetAmount({String? month}) async {
    final key = month ?? currentMonthKey;
    _clearCache();
    _clearAnalyticsCache();
    await _driftMonthlyBudgetRepository.delete(key);
    _monthlyBudgetCache.remove(key);
    if (key == currentMonthKey) {
      _currentMonthlyBudget = null;
    }
    if (key == monthKey(budgetPeriod.periodOf(DateTime.now()))) {
      settings = settings.copyWith(clearMonthlyBudget: true);
      await _settingsService.save(settings);
    }
    notifyListeners();
  }

  Future<bool> copyBudgetFromPreviousMonth() async {
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final prevKey = monthKey(prevMonth);
    final prevBudget = await getMonthlyBudgetForMonth(prevKey);
    if (prevBudget != null && prevBudget.amount > 0) {
      await setMonthlyBudgetAmount(prevBudget.amount);
      return true;
    }
    return false;
  }

  double getCurrentMonthTotalSpent() {
    if (_cachedTotalSpent != null) return _cachedTotalSpent!;
    _cachedTotalSpent = currentMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
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
    io.Directory? zipExtractDir,
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
      {List<GroceryItemDraft>? groceryItems,
      wm_fuel.FuelTransactionDraft? fuelTransaction}) async {
    await _driftExpenseRepository.update(expense,
        groceryItems: groceryItems, fuelTransaction: fuelTransaction);
    await refresh();
  }

  Future<wm_fuel.FuelTransaction?> fuelTransactionForExpense(
      String expenseId) async {
    return _driftFuelRepository.getByExpenseId(expenseId);
  }

  Future<void> addEssentialTemplate(
    wm_essential.EssentialExpenseTemplate template, {
    List<wm_essential.FuelTemplateComponent>? fuelComponents,
  }) async {
    await _driftEssentialExpenseRepository.create(template,
        fuelComponents: fuelComponents);
    await refresh();
  }

  Future<void> updateEssentialTemplate(
    wm_essential.EssentialExpenseTemplate template, {
    List<wm_essential.FuelTemplateComponent>? fuelComponents,
  }) async {
    await _driftEssentialExpenseRepository.update(template,
        fuelComponents: fuelComponents);
    await refresh();
  }

  Future<void> deleteEssentialTemplate(String id) async {
    await _driftEssentialExpenseRepository.delete(id);
    await refresh();
  }

  Future<void> toggleEssentialTemplateActive(String id, bool isActive) async {
    await _driftEssentialExpenseRepository.toggleActive(id, isActive);
    await refresh();
  }

  Map<String, double> getMonthlyEssentialSummary(DateTime month) {
    double expectedTotal = 0.0;
    for (final t in essentialTemplates) {
      if (!t.isActive || t.isDeleted) continue;
      expectedTotal += t.computedExpectedAmount;
    }

    final essentialCategoryIds = essentialTemplates
        .where((t) => t.isActive && !t.isDeleted)
        .map((t) => t.categoryId)
        .toSet();

    // Default essential categories recognized in personal finance
    essentialCategoryIds.addAll(['fuel', 'rent', 'electricity', 'gas', 'water', 'internet']);

    final monthExpenses = expenses.where((e) {
      if (e.deletedAt != null) return false;
      try {
        final d = parseIsoDate(e.date);
        return budgetPeriod.contains(month, d);
      } catch (_) {
        return false;
      }
    });

    double actualTotal = 0.0;
    for (final e in monthExpenses) {
      if (essentialCategoryIds.contains(e.categoryId)) {
        actualTotal += e.amount;
      }
    }

    return {
      'expected': wm_fuel.roundToTwoDecimals(expectedTotal),
      'actual': wm_fuel.roundToTwoDecimals(actualTotal),
    };
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

  Future<List<MonthlyBudget>> listAllMonthlyBudgetsForExport() async {
    return _driftMonthlyBudgetRepository.listAll();
  }

  /// Backup v2 extended section (every table the legacy sections do not own),
  /// or null when no Drift database is attached (tests, screenshots).
  Future<Map<String, Object?>?> exportExtendedTables() async {
    final db = _driftDatabase;
    if (db == null) return null;
    return BackupExtendedTables.export(db);
  }

  /// Drift schema version recorded in v2 backups.
  int? get backupSchemaVersion =>
      _driftDatabase == null ? null : local.WalletMeltDatabase.currentSchemaVersion;

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

  Future<List<Merchant>> getMerchantSuggestions({String? query, int limit = 8}) async {
    return _driftStoreRepository.getSuggestions(query: query, limit: limit);
  }

  Future<Merchant> saveMerchant({
    required String name,
    String? defaultCategoryId,
    String? notes,
    bool isFavorite = false,
  }) async {
    final result = await _driftStoreRepository.saveMerchant(
      name: name,
      defaultCategoryId: defaultCategoryId,
      notes: notes,
      isFavorite: isFavorite,
    );
    await refresh();
    return result;
  }

  Future<Merchant> updateMerchant(Merchant merchant) async {
    final result = await _driftStoreRepository.updateMerchant(merchant);
    await refresh();
    return result;
  }

  Future<void> archiveMerchant(String id) async {
    await _driftStoreRepository.archiveMerchant(id);
    await refresh();
  }

  Future<void> restoreMerchant(String id) async {
    await _driftStoreRepository.restoreMerchant(id);
    await refresh();
  }

  Future<void> toggleMerchantFavorite(String id) async {
    await _driftStoreRepository.toggleFavorite(id);
    await refresh();
  }

  Future<void>? _renewalsInFlight;

  /// Generates due subscription renewal expenses. Concurrent callers share a
  /// single in-flight run so overlapping refreshes cannot double-generate.
  Future<void> processSubscriptionRenewals() {
    final running = _renewalsInFlight;
    if (running != null) return running;
    final run = _processSubscriptionRenewals().whenComplete(() {
      _renewalsInFlight = null;
    });
    _renewalsInFlight = run;
    return run;
  }

  Future<void> _processSubscriptionRenewals() async {
    final subs = await _driftSubscriptionRepository.listAll();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    for (final sub in subs) {
      if (sub.status != SubscriptionStatus.active) continue;

      var currentNextDateStr = sub.nextOccurrenceDate;
      if (DateTime.tryParse(currentNextDateStr) == null) {
        debugPrint(
            'Skipping renewals for "${sub.name}": bad date $currentNextDateStr');
        continue;
      }

      // Pure computation first; nothing is written until the whole catch-up
      // for this subscription is known, then it is saved atomically.
      var updatedSub = sub;
      final drafts = <ExpenseDraft>[];
      final renewalAccountId = await _renewalAccountIdFor(sub);

      while (currentNextDateStr.compareTo(todayStr) <= 0) {
        final parsedDate = DateTime.parse(currentNextDateStr);

        drafts.add(ExpenseDraft(
          amount: sub.amount + (sub.taxAmount ?? 0.0),
          currency: sub.currency,
          categoryId: sub.categoryId,
          title: '${sub.name} (Recurring Renewal)',
          date: parsedDate,
          vendor: sub.name,
          notes: 'Auto-generated subscription renewal for ${sub.name}',
          subtotalAmount: sub.amount,
          taxAmount: sub.taxAmount,
          accountId: renewalAccountId,
        ));

        final nextDate = sub.calculateNextRenewalDate(parsedDate);
        currentNextDateStr = nextDate.toIso8601String().substring(0, 10);

        updatedSub = updatedSub.copyWith(
          nextOccurrenceDate: currentNextDateStr,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      if (drafts.isEmpty) continue;
      try {
        await _driftSubscriptionRepository.applyRenewals(
          updated: updatedSub,
          drafts: drafts,
          expenseRepository: _driftExpenseRepository,
        );
      } catch (error) {
        // The transaction rolled back: no partial expenses, date unchanged.
        debugPrint(
            'Renewal for "${sub.name}" failed and was rolled back: $error');
      }
    }
  }

  /// The subscription's account, but only when it is usable for this renewal:
  /// still active and in the subscription's currency (ADR-0014).
  Future<String?> _renewalAccountIdFor(wm_sub.Subscription sub) async {
    final id = sub.accountId;
    final repo = _accountRepository;
    if (id == null || repo == null) return null;
    final account = await repo.getById(id);
    if (account == null ||
        account.isArchived ||
        account.deletedAt != null ||
        account.currency != sub.currency) {
      return null;
    }
    return id;
  }

  Future<void> setDebtAccount(String debtId, String? accountId) async {
    await _driftDebtRepository.setAccount(debtId, accountId);
    await refresh();
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
    try {
      await _driftDatabase?.customStatement('VACUUM;');
    } catch (_) {}
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

  /// Changes the day on which each budget period starts (ADR-0013). All
  /// history is regrouped; no stored data is rewritten.
  Future<void> setBudgetPeriodStartDay(int day) async {
    final clamped = day.clamp(1, BudgetPeriod.maxStartDay);
    if (clamped == settings.budgetPeriodStartDay) return;
    settings = settings.copyWith(budgetPeriodStartDay: clamped);
    await _settingsService.save(settings);
    _monthlyBudgetCache.clear();
    _selectedMonth = budgetPeriod.periodOf(DateTime.now());
    await refresh();
  }

  Future<void> previousMonth() async {
    _clearCache();
    _clearAnalyticsCache();
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    currentBudgets = await _listBudgetsForMonth(currentMonthKey);
    _currentMonthlyBudget = await _driftMonthlyBudgetRepository.getForMonth(currentMonthKey);
    _monthlyBudgetCache[currentMonthKey] = _currentMonthlyBudget;
    _updateCurrentMonthExpenses();
    notifyListeners();
  }

  Future<void> nextMonth() async {
    _clearCache();
    _clearAnalyticsCache();
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    currentBudgets = await _listBudgetsForMonth(currentMonthKey);
    _currentMonthlyBudget = await _driftMonthlyBudgetRepository.getForMonth(currentMonthKey);
    _monthlyBudgetCache[currentMonthKey] = _currentMonthlyBudget;
    _updateCurrentMonthExpenses();
    notifyListeners();
  }

  Future<void> setSelectedMonth(DateTime month) async {
    _clearCache();
    _clearAnalyticsCache();
    selectedMonth = DateTime(month.year, month.month);
    currentBudgets = await _listBudgetsForMonth(currentMonthKey);
    _currentMonthlyBudget = await _driftMonthlyBudgetRepository.getForMonth(currentMonthKey);
    _monthlyBudgetCache[currentMonthKey] = _currentMonthlyBudget;
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

class _FakeDriftEssentialExpenseRepository extends DriftEssentialExpenseRepository {
  _FakeDriftEssentialExpenseRepository() : super(_dummyDb);
  @override
  Future<List<wm_essential.EssentialExpenseTemplate>> listAll({bool includeDeleted = false}) async => [];
}

class _FakeDriftFuelRepository extends DriftFuelRepository {
  _FakeDriftFuelRepository() : super(_dummyDb);
  @override
  Future<wm_fuel.FuelTransaction?> getByExpenseId(String expenseId) async => null;
  @override
  Future<List<wm_fuel.FuelTransaction>> listAll() async => [];
}

class _FakeDriftStoreRepository extends DriftStoreRepository {
  _FakeDriftStoreRepository() : super(_dummyDb);
  @override
  Future<List<Merchant>> listSavedMerchants() async => [];
  @override
  Future<List<Merchant>> getSuggestions({String? query, int limit = 8}) async => [];
  @override
  Future<String?> recordMerchantHistory(String merchantName) async => null;
}

class _FakeDriftMonthlyBudgetRepository extends DriftMonthlyBudgetRepository {
  _FakeDriftMonthlyBudgetRepository() : super(_dummyDb);
  final Map<String, MonthlyBudget> _fakeStore = {};

  @override
  Future<MonthlyBudget?> getForMonth(String month) async => _fakeStore[month];

  @override
  Future<List<MonthlyBudget>> listAll() async => _fakeStore.values.toList();

  @override
  Future<void> upsert({
    required String month,
    required double amount,
    required String currency,
  }) async {
    final now = DateTime.now().toIso8601String();
    _fakeStore[month] = MonthlyBudget(
      id: 'fake_$month',
      month: month,
      amount: amount,
      currency: currency,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> delete(String month) async {
    _fakeStore.remove(month);
  }
}

local.WalletMeltDatabase? _lazyDummyDb;
local.WalletMeltDatabase get _dummyDb {
  if (_lazyDummyDb == null) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    _lazyDummyDb = local.WalletMeltDatabase.memory();
  }
  return _lazyDummyDb!;
}
