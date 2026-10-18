import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/financial_metrics_calculator.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/analytics/income_planner.dart';
import 'package:wallet_melt/src/analytics/spending_analytics.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_encoder.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/income.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/utils/budget_period.dart';
import 'package:wallet_melt/src/utils/insights.dart';

class _Settings extends SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}

Expense _expense(String id, String date, double amount) => Expense(
      id: id,
      amount: amount,
      currency: 'PKR',
      categoryId: 'grocery',
      title: id,
      date: '${date}T00:00:00.000',
      isRecurring: false,
      createdAt: 't',
      updatedAt: 't',
    );

void main() {
  const p25 = BudgetPeriod(25);
  final june = DateTime(2026, 6);
  final expenses = [
    _expense('before', '2026-06-24', 100), // May period
    _expense('start', '2026-06-25', 200), // June period
    _expense('spill', '2026-07-03', 300), // June period
    _expense('last', '2026-07-24', 400), // June period (last day)
    _expense('next', '2026-07-25', 500), // July period
  ];

  group('spending snapshot', () {
    test('start day 25 groups by payday and counts days from 25 Jun', () {
      final snap = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: june,
        now: DateTime(2026, 7, 25), // everything is in the past
        currency: 'PKR',
        period: p25,
      );
      expect(snap.currentTotal, 200 + 300 + 400);
      expect(snap.previousTotal, 100);
      expect(snap.daysInMonth, 30);
      expect(snap.daysElapsed, 30);
      expect(snap.isFutureMonth, isFalse);
    });

    test('mid-period snapshot only counts elapsed days and excludes future',
        () {
      final snap = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: june,
        now: DateTime(2026, 7, 3, 12),
        currency: 'PKR',
        period: p25,
      );
      expect(snap.daysElapsed, 9);
      expect(snap.currentTotal, 200 + 300); // 24 Jul is still in the future
    });

    test('default period reproduces calendar-month results', () {
      final snap = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: june,
        now: DateTime(2026, 7, 30),
        currency: 'PKR',
      );
      expect(snap.currentTotal, 100 + 200); // 25 and 24 June
      expect(snap.daysInMonth, 30);
    });
  });

  group('daily allowance', () {
    test('uses days left in the pay period, not the calendar month', () {
      final result = FinancialMetricsCalculator.calculateDailySpendAllowance(
        monthlyBudget: 22000,
        totalSpent: 0,
        month: june,
        now: DateTime(2026, 7, 3),
        period: p25,
      );
      expect(result.isCurrentMonth, isTrue);
      expect(result.daysRemaining, 22);
      expect(result.dailyAllowance, 1000);
    });

    test('calendar default is unchanged', () {
      expect(
        FinancialMetricsCalculator.calculateDaysRemainingInMonth(
            DateTime(2026, 6), DateTime(2026, 6, 13)),
        18,
      );
    });
  });

  group('grouping and income planning', () {
    test('groupExpensesByMonth buckets by period start month', () {
      final grouped = groupExpensesByMonth(expenses, p25);
      expect(grouped.keys.toSet(), {'2026-05', '2026-06', '2026-07'});
      expect(grouped['2026-06']!.map((e) => e.id).toSet(),
          {'start', 'spill', 'last'});
    });

    test('expected income counts the pay period only', () {
      Income received(String date, int amount) => Income(
            id: date,
            title: 't',
            source: IncomeSource.salary,
            amountMinorUnits: amount,
            currency: 'PKR',
            date: '${date}T00:00:00.000',
            createdAt: 't',
            updatedAt: 't',
          );
      final total = IncomePlanner.expectedForMonth(
        month: june,
        currency: 'PKR',
        received: [
          received('2026-06-24', 1), // previous period
          received('2026-06-25', 1000),
          received('2026-07-24', 2000),
          received('2026-07-25', 4), // next period
        ],
        schedules: const [],
        period: p25,
      );
      expect(total, 3000);
    });
  });

  group('AppState', () {
    test('changing the start day regroups current-period expenses', () async {
      final db = WalletMeltDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftExpenseRepository(db);
      for (final e in expenses) {
        await repo.create(ExpenseDraft(
          amount: e.amount,
          currency: 'PKR',
          categoryId: 'grocery',
          title: e.id,
          date: DateTime.parse(e.date),
        ));
      }
      final state = AppState.test(
        driftCategoryRepository: DriftCategoryRepository(db),
        driftExpenseRepository: repo,
        driftBudgetRepository: DriftBudgetRepository(db),
        settingsService: _Settings(),
        settings: WalletMeltSettings.defaults.copyWith(
          hasCompletedOnboarding: true,
          currency: 'PKR',
        ),
      );
      await state.refresh();
      state.selectedMonth = june;
      expect(state.currentMonthExpenses.map((e) => e.title).toSet(),
          {'before', 'start'},
          reason: 'calendar June holds 24 and 25 June');

      await state.setBudgetPeriodStartDay(25);
      expect(state.budgetPeriod, p25);
      state.selectedMonth = june;
      expect(state.currentMonthExpenses.map((e) => e.title).toSet(),
          {'start', 'spill', 'last'});
      expect(state.settings.budgetPeriodStartDay, 25);

      // Out-of-range values clamp.
      await state.setBudgetPeriodStartDay(99);
      expect(state.settings.budgetPeriodStartDay, 28);
    });
  });

  test('backup settings carry the start day', () {
    final json = const WalletMeltJsonBackupEncoder().encode(
      expenses: const [],
      groceryItems: const [],
      categories: const [],
      budgets: const [],
      settings: WalletMeltSettings.defaults.copyWith(budgetPeriodStartDay: 25),
      exportedAt: DateTime(2026, 6, 14),
    );
    expect(json, contains('"budget_period_start_day": 25'));
  });
}
