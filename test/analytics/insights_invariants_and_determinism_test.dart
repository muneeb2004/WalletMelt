import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/insight_engine.dart';
import 'package:wallet_melt/src/analytics/spending_analytics.dart';
import 'package:wallet_melt/src/analytics/summary_builder.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/essential_expense.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/insight_data.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/types/subscription.dart';
import 'package:wallet_melt/src/utils/insights.dart';

void main() {
  final categories = [
    const Category(
      id: 'cat_grocery',
      name: 'Grocery',
      icon: 'grocery',
      color: '#4CAF50',
      isDefault: true,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
    const Category(
      id: 'cat_dining',
      name: 'Dining',
      icon: 'restaurant',
      color: '#FF9800',
      isDefault: true,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
    const Category(
      id: 'cat_fuel',
      name: 'Fuel',
      icon: 'local_gas_station',
      color: '#F44336',
      isDefault: true,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
    const Category(
      id: 'cat_utilities',
      name: 'Utilities',
      icon: 'bolt',
      color: '#2196F3',
      isDefault: true,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
  ];

  final budgets = [
    const CategoryBudget(
      id: 'b_grocery',
      categoryId: 'cat_grocery',
      amount: 20000,
      month: '2026-08',
      currency: 'PKR',
      createdAt: '2026-08-01',
      updatedAt: '2026-08-01',
    ),
    const CategoryBudget(
      id: 'b_dining',
      categoryId: 'cat_dining',
      amount: 10000,
      month: '2026-08',
      currency: 'PKR',
      createdAt: '2026-08-01',
      updatedAt: '2026-08-01',
    ),
  ];

  final essentialTemplates = [
    const EssentialExpenseTemplate(
      id: 'tmpl_1',
      name: 'Electricity',
      expectedAmount: 12000,
      categoryId: 'cat_utilities',
      frequency: 'monthly',
      isActive: true,
      isFuel: false,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
  ];

  final subscriptions = [
    const Subscription(
      id: 'sub_1',
      name: 'Internet',
      amount: 3500,
      currency: 'PKR',
      categoryId: 'cat_utilities',
      billingCycle: 'monthly',
      startDate: '2026-01-01',
      nextOccurrenceDate: '2026-09-01',
      status: SubscriptionStatus.active,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
  ];

  List<Expense> generateTestExpenses() {
    return [
      Expense(
        id: 'exp_1',
        amount: 5000,
        currency: 'PKR',
        categoryId: 'cat_grocery',
        title: 'Supermarket',
        date: '2026-08-05',
        vendor: 'Carrefour',
        isRecurring: false,
        createdAt: '2026-08-05',
        updatedAt: '2026-08-05',
      ),
      Expense(
        id: 'exp_2',
        amount: 8000,
        currency: 'PKR',
        categoryId: 'cat_grocery',
        title: 'Bulk grocery',
        date: '2026-08-10',
        vendor: 'Carrefour',
        isRecurring: false,
        createdAt: '2026-08-10',
        updatedAt: '2026-08-10',
      ),
      Expense(
        id: 'exp_3',
        amount: -1000,
        currency: 'PKR',
        categoryId: 'cat_grocery',
        title: 'Returned Item',
        date: '2026-08-12',
        vendor: 'Carrefour',
        isRecurring: false,
        createdAt: '2026-08-12',
        updatedAt: '2026-08-12',
      ),
      Expense(
        id: 'exp_4',
        amount: 4500,
        currency: 'PKR',
        categoryId: 'cat_dining',
        title: 'Dinner KFC',
        date: '2026-08-15',
        vendor: 'KFC',
        isRecurring: false,
        createdAt: '2026-08-15',
        updatedAt: '2026-08-15',
      ),
      Expense(
        id: 'exp_5',
        amount: 3500,
        currency: 'PKR',
        categoryId: 'cat_utilities',
        title: 'Fiber Internet',
        date: '2026-08-02',
        vendor: 'StormFiber',
        isRecurring: true,
        createdAt: '2026-08-02',
        updatedAt: '2026-08-02',
      ),
      Expense(
        id: 'exp_6',
        amount: 12000,
        currency: 'PKR',
        categoryId: 'cat_utilities',
        title: 'Electric Bill',
        date: '2026-08-18',
        vendor: 'KElectric',
        isRecurring: false,
        createdAt: '2026-08-18',
        updatedAt: '2026-08-18',
      ),
      // Previous month expenses
      Expense(
        id: 'exp_prev_1',
        amount: 6000,
        currency: 'PKR',
        categoryId: 'cat_grocery',
        title: 'Prev Supermarket',
        date: '2026-07-10',
        vendor: 'Carrefour',
        isRecurring: false,
        createdAt: '2026-07-10',
        updatedAt: '2026-07-10',
      ),
      Expense(
        id: 'exp_prev_2',
        amount: 3000,
        currency: 'PKR',
        categoryId: 'cat_dining',
        title: 'Prev Lunch',
        date: '2026-07-15',
        vendor: 'Subway',
        isRecurring: false,
        createdAt: '2026-07-15',
        updatedAt: '2026-07-15',
      ),
      // Future-dated expense (should be excluded globally)
      Expense(
        id: 'exp_future',
        amount: 50000,
        currency: 'PKR',
        categoryId: 'cat_fuel',
        title: 'Future Expense',
        date: '2026-08-30',
        vendor: 'Shell',
        isRecurring: false,
        createdAt: '2026-08-30',
        updatedAt: '2026-08-30',
      ),
    ];
  }

  group('Purity Invariant Tests', () {
    test('SpendingAnalytics.buildSnapshot does not mutate input expenses', () {
      final expenses = generateTestExpenses();
      final originalIds = expenses.map((e) => e.id).toList();

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: DateTime(2026, 8),
        now: DateTime(2026, 8, 24),
        currency: 'PKR',
      );

      expect(expenses.map((e) => e.id).toList(), originalIds);
      expect(snapshot.currentTotal, isNotNull);
    });

    test('SummaryBuilder.build does not mutate snapshot or categories', () {
      final expenses = generateTestExpenses();
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: DateTime(2026, 8),
        now: DateTime(2026, 8, 24),
        currency: 'PKR',
      );

      final originalCatLength = categories.length;
      final originalMerchantCount = snapshot.currentMerchants.length;

      SummaryBuilder.build(snapshot: snapshot, categories: categories);

      expect(categories.length, originalCatLength);
      expect(snapshot.currentMerchants.length, originalMerchantCount);
    });

    test('InsightEngine.generate does not mutate input collections', () {
      final expenses = generateTestExpenses();
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: DateTime(2026, 8),
        now: DateTime(2026, 8, 24),
        currency: 'PKR',
      );

      final originalBudgetsLength = budgets.length;
      final originalTemplatesLength = essentialTemplates.length;

      InsightEngine.generate(
        snapshot: snapshot,
        categories: categories,
        budgets: budgets,
        essentialTemplates: essentialTemplates,
        subscriptions: subscriptions,
        monthlyBudgetAmount: 100000,
      );

      expect(budgets.length, originalBudgetsLength);
      expect(essentialTemplates.length, originalTemplatesLength);
    });
  });

  group('Mathematical Invariant Tests', () {
    test('Sum of currentByCategory equals currentTotal and sum of previousByCategory equals previousTotal', () {
      final expenses = generateTestExpenses();
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: DateTime(2026, 8),
        now: DateTime(2026, 8, 24),
        currency: 'PKR',
      );

      final curSum = snapshot.currentByCategory.values.fold(0.0, (a, b) => a + b);
      final prevSum = snapshot.previousByCategory.values.fold(0.0, (a, b) => a + b);

      expect(curSum, closeTo(snapshot.currentTotal, 0.001));
      expect(prevSum, closeTo(snapshot.previousTotal, 0.001));
    });

    test('Essential vs Other reconciled totals strictly equal currentTotal', () {
      final expenses = generateTestExpenses();
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: DateTime(2026, 8),
        now: DateTime(2026, 8, 24),
        currency: 'PKR',
      );

      final cards = InsightEngine.generate(
        snapshot: snapshot,
        categories: categories,
        budgets: budgets,
        essentialTemplates: essentialTemplates,
        subscriptions: subscriptions,
        monthlyBudgetAmount: 100000,
      );

      final essentialCard = cards.firstWhere((c) => c.data is EssentialSplitData);
      final data = essentialCard.data as EssentialSplitData;

      expect(data.essentialTotal + data.otherTotal, closeTo(snapshot.currentTotal, 0.001));
    });

    test('All generated card priorities are strictly within [0.0, 2.0]', () {
      final expenses = generateTestExpenses();
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: DateTime(2026, 8),
        now: DateTime(2026, 8, 24),
        currency: 'PKR',
      );

      final cards = InsightEngine.generate(
        snapshot: snapshot,
        categories: categories,
        budgets: budgets,
        essentialTemplates: essentialTemplates,
        subscriptions: subscriptions,
        monthlyBudgetAmount: 100000,
      );

      for (final card in cards) {
        expect(card.priority, greaterThanOrEqualTo(0.0));
        expect(card.priority, lessThanOrEqualTo(2.0));
      }
    });

    test('Future-dated transactions are strictly excluded from snapshot, summaries, and cards', () {
      final expenses = generateTestExpenses();
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: DateTime(2026, 8),
        now: DateTime(2026, 8, 24),
        currency: 'PKR',
      );

      // exp_future (50,000 on cat_fuel on 2026-08-30) must not appear in any category or total
      expect(snapshot.currentByCategory.containsKey('cat_fuel'), isFalse);
      expect(snapshot.currentExpenses.any((e) => e.id == 'exp_future'), isFalse);
      expect(snapshot.currentTotal, 32000.0); // 5000 + 8000 - 1000 + 4500 + 3500 + 12000
    });
  });

  group('Determinism & Shuffle Invariance Tests', () {
    test('Reordered input expenses produce identical analytical totals, insight cards, and summaries', () {
      final baseExpenses = generateTestExpenses();
      final nowTime = DateTime(2026, 8, 24);
      final selectedMonth = DateTime(2026, 8);

      final snap1 = SpendingAnalytics.buildSnapshot(
        expenses: baseExpenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );
      final cards1 = InsightEngine.generate(
        snapshot: snap1,
        categories: categories,
        budgets: budgets,
        essentialTemplates: essentialTemplates,
        subscriptions: subscriptions,
        monthlyBudgetAmount: 100000,
      );
      final sum1 = SummaryBuilder.build(snapshot: snap1, categories: categories);
      final insights1 = buildMonthlyInsightsFromSnapshot(
        snapshot: snap1,
        categories: categories,
        budgets: budgets,
      );

      // Shuffle 10 times with different seeds
      for (var seed = 1; seed <= 10; seed++) {
        final shuffled = [...baseExpenses]..shuffle(Random(seed));

        final snap2 = SpendingAnalytics.buildSnapshot(
          expenses: shuffled,
          selectedMonth: selectedMonth,
          now: nowTime,
          currency: 'PKR',
        );
        final cards2 = InsightEngine.generate(
          snapshot: snap2,
          categories: categories,
          budgets: budgets,
          essentialTemplates: essentialTemplates,
          subscriptions: subscriptions,
        monthlyBudgetAmount: 100000,
        );
        final sum2 = SummaryBuilder.build(snapshot: snap2, categories: categories);
        final insights2 = buildMonthlyInsightsFromSnapshot(
          snapshot: snap2,
          categories: categories,
          budgets: budgets,
        );

        // Identical totals & maps
        expect(snap2.currentTotal, snap1.currentTotal);
        expect(snap2.previousTotal, snap1.previousTotal);
        expect(snap2.currentPositiveTotal, snap1.currentPositiveTotal);
        expect(snap2.currentByCategory, snap1.currentByCategory);

        // Identical card ordering, IDs, priorities
        expect(cards2.length, cards1.length);
        for (var i = 0; i < cards1.length; i++) {
          expect(cards2[i].id, cards1[i].id);
          expect(cards2[i].priority, cards1[i].priority);
          expect(cards2[i].title, cards1[i].title);
        }

        // Identical summary rankings
        expect(
          sum2.topCategories.map((c) => c.categoryId).toList(),
          sum1.topCategories.map((c) => c.categoryId).toList(),
        );
        expect(
          sum2.topMerchants.map((m) => m.merchantKey).toList(),
          sum1.topMerchants.map((m) => m.merchantKey).toList(),
        );
        expect(
          sum2.largestExpenses.map((e) => e.id).toList(),
          sum1.largestExpenses.map((e) => e.id).toList(),
        );

        // Identical recentExpenses ordering via date DESC -> id ASC tie-breaker
        expect(
          insights2.recentExpenses.map((e) => e.id).toList(),
          insights1.recentExpenses.map((e) => e.id).toList(),
        );
      }
    });
  });

  group('AppState Generation Token & Same-Day Caching Invariant', () {
    test('Repeated same-day calls reuse identical cached snapshot without regeneration', () {
      final appState = AppState();
      appState.settings = WalletMeltSettings.defaults;
      appState.categories = categories;
      appState.expenses = generateTestExpenses();
      appState.selectedMonth = DateTime(2026, 8);

      final snap1 = appState.spendingSnapshot;
      final snap2 = appState.spendingSnapshot;
      expect(identical(snap1, snap2), isTrue);

      final cards1 = appState.insightCards;
      final cards2 = appState.insightCards;
      expect(identical(cards1, cards2), isTrue);

      final sum1 = appState.spendingSummaries;
      final sum2 = appState.spendingSummaries;
      expect(identical(sum1, sum2), isTrue);
    });

    test('Expense mutation increments generation token and forces cache rebuild', () {
      final appState = AppState();
      appState.settings = WalletMeltSettings.defaults;
      appState.categories = categories;
      appState.expenses = generateTestExpenses();
      appState.selectedMonth = DateTime(2026, 8);

      final snap1 = appState.spendingSnapshot;

      // Add new expense
      appState.expenses = [
        ...appState.expenses,
        Expense(
          id: 'exp_new',
          amount: 2500,
          currency: 'PKR',
          categoryId: 'cat_dining',
          title: 'Extra Dining',
          date: '2026-08-20',
          isRecurring: false,
          createdAt: '2026-08-20',
          updatedAt: '2026-08-20',
        ),
      ];
      appState.selectedMonth = DateTime(2026, 8); // Re-trigger update

      final snap2 = appState.spendingSnapshot;
      expect(identical(snap1, snap2), isFalse);
      expect(snap2.currentTotal, snap1.currentTotal + 2500.0);
    });
  });
}
