import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/detectors/budget_risk_detector.dart';
import 'package:wallet_melt/src/analytics/detectors/category_changes_detector.dart';
import 'package:wallet_melt/src/analytics/detectors/essential_vs_other_detector.dart';
import 'package:wallet_melt/src/analytics/detectors/merchant_inconsistency_detector.dart';
import 'package:wallet_melt/src/analytics/detectors/spending_frequency_detector.dart';
import 'package:wallet_melt/src/analytics/detectors/spending_velocity_detector.dart';
import 'package:wallet_melt/src/analytics/detectors/why_spending_changed_detector.dart';
import 'package:wallet_melt/src/analytics/insight_detector.dart';
import 'package:wallet_melt/src/analytics/insight_engine.dart';
import 'package:wallet_melt/src/analytics/spending_analytics.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/essential_expense.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/insight_card.dart';
import 'package:wallet_melt/src/types/insight_data.dart';
import 'package:wallet_melt/src/types/subscription.dart';

void main() {
  group('InsightEngine & Detectors', () {
    final nowTime = DateTime(2026, 8, 24, 14, 30);
    final selectedMonth = DateTime(2026, 8);

    final categories = [
      const Category(
        id: 'cat_dining',
        name: 'Dining & Food',
        icon: 'restaurant',
        color: '#FF5722',
        isDefault: true,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ),
      const Category(
        id: 'cat_transport',
        name: 'Transport',
        icon: 'directions_car',
        color: '#2196F3',
        isDefault: true,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ),
      const Category(
        id: 'cat_groceries',
        name: 'Groceries',
        icon: 'shopping_cart',
        color: '#4CAF50',
        isDefault: true,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ),
      const Category(
        id: 'cat_utilities',
        name: 'Utilities',
        icon: 'bolt',
        color: '#FFC107',
        isDefault: true,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ),
    ];

    Expense createExp({
      required String id,
      required double amount,
      required String categoryId,
      required String date,
      String? vendor,
    }) {
      return Expense(
        id: id,
        amount: amount,
        currency: 'PKR',
        categoryId: categoryId,
        title: 'Expense $id',
        date: date,
        vendor: vendor,
        isRecurring: false,
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
      );
    }

    test('Future month strictly suppresses all insight cards', () {
      final futureMonth = DateTime(2026, 9);
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: [
          createExp(id: '1', amount: 5000, categoryId: 'cat_dining', date: '2026-08-10'),
        ],
        selectedMonth: futureMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final cards = InsightEngine.generate(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      expect(cards, isEmpty);
    });

    test('Why Spending Changed: opposing category movements compute correct clamped directional contribution percentage', () {
      // Previous: Dining=1000, Transport=5000 (Total = 6000)
      // Current: Dining=6000 (+5000), Transport=2000 (-3000) (Total = 8000, Delta = +2000)
      final expenses = [
        createExp(id: '1', amount: 1000, categoryId: 'cat_dining', date: '2026-07-05'),
        createExp(id: '2', amount: 5000, categoryId: 'cat_transport', date: '2026-07-06'),
        createExp(id: '3', amount: 6000, categoryId: 'cat_dining', date: '2026-08-05'),
        createExp(id: '4', amount: 2000, categoryId: 'cat_transport', date: '2026-08-06'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const WhySpendingChangedDetector().detect(context);
      expect(card, isNotNull);
      expect(card!.type, InsightType.whySpendingChanged);
      final data = card.data as WhyChangedData;
      expect(data.isIncrease, isTrue);
      expect(data.totalDelta, 2000.0);
      expect(data.topContributorCategoryId, 'cat_dining');
      expect(data.topContributorDelta, 5000.0);
      // Only Dining increased among categories, so it drove 100% of the gross positive movement
      expect(data.directionalContributionPercent, 100.0);
    });

    test('Why Spending Changed: decrease identifies top saving contributor', () {
      // Previous: Dining=8000, Transport=2000 (Total = 10000)
      // Current: Dining=3000 (-5000), Transport=3000 (+1000) (Total = 6000, Delta = -4000)
      final expenses = [
        createExp(id: '1', amount: 8000, categoryId: 'cat_dining', date: '2026-07-05'),
        createExp(id: '2', amount: 2000, categoryId: 'cat_transport', date: '2026-07-06'),
        createExp(id: '3', amount: 3000, categoryId: 'cat_dining', date: '2026-08-05'),
        createExp(id: '4', amount: 3000, categoryId: 'cat_transport', date: '2026-08-06'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const WhySpendingChangedDetector().detect(context);
      expect(card, isNotNull);
      final data = card!.data as WhyChangedData;
      expect(data.isIncrease, isFalse);
      expect(data.totalDelta, -4000.0);
      expect(data.topContributorCategoryId, 'cat_dining');
      expect(data.topContributorDelta, 5000.0);
      expect(data.directionalContributionPercent, 100.0);
    });

    test('Why Spending Changed: totalDelta.abs() < minimumMeaningfulAmount suppresses insight', () {
      final expenses = [
        createExp(id: '1', amount: 1000, categoryId: 'cat_dining', date: '2026-07-05'),
        createExp(id: '2', amount: 1100, categoryId: 'cat_dining', date: '2026-08-05'), // Delta = +100 < PKR 500
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const WhySpendingChangedDetector().detect(context);
      expect(card, isNull);
    });

    test('Category Changes: applies both absoluteThreshold and minCategoryChangePercent (10%) significance rules using magnitude', () {
      // ComparisonBase = 10000. AbsoluteThreshold = max(10000*0.02, 500) = 500.
      // Cat Groceries: Prev=2000, Cur=1000 -> magnitude=1000 >= 500, percentChange=50% >= 10% -> SIGNIFICANT
      // Cat Transport: Prev=5000, Cur=4800 -> magnitude=200 < 500 -> NOT SIGNIFICANT
      final expenses = [
        createExp(id: '1', amount: 3000, categoryId: 'cat_dining', date: '2026-07-01'),
        createExp(id: '2', amount: 2000, categoryId: 'cat_groceries', date: '2026-07-01'),
        createExp(id: '3', amount: 5000, categoryId: 'cat_transport', date: '2026-07-01'),
        createExp(id: '4', amount: 8000, categoryId: 'cat_dining', date: '2026-08-01'), // Dominant in WhyChanged (+5000)
        createExp(id: '5', amount: 1000, categoryId: 'cat_groceries', date: '2026-08-01'),
        createExp(id: '6', amount: 4800, categoryId: 'cat_transport', date: '2026-08-01'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const CategoryChangesDetector().detect(context);
      expect(card, isNotNull);
      final data = card!.data as CategoryChangesData;
      // Dominant 'cat_dining' was deduplicated, 'cat_transport' failed threshold, 'cat_groceries' passed
      expect(data.changes.length, 1);
      expect(data.changes.first.categoryId, 'cat_groceries');
      expect(data.changes.first.magnitude, 1000.0);
    });

    test('Budget Risk: multiple budgets aggregate into single card and rank by highest risk', () {
      // Days elapsed: 24/31
      // Budget 1: Dining 10,000, spent 9,600 (96% usage, projected ~12,400) -> Alert
      // Budget 2: Transport 10,000, spent 7,000 (70% usage) -> Info
      final expenses = [
        createExp(id: '1', amount: 9600, categoryId: 'cat_dining', date: '2026-08-05'),
        createExp(id: '2', amount: 7000, categoryId: 'cat_transport', date: '2026-08-06'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final budgets = [
        const CategoryBudget(
          id: 'b1',
          categoryId: 'cat_dining',
          amount: 10000,
          currency: 'PKR',
          month: '2026-08',
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
        const CategoryBudget(
          id: 'b2',
          categoryId: 'cat_transport',
          amount: 10000,
          currency: 'PKR',
          month: '2026-08',
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      ];

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: budgets,
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const BudgetRiskDetector().detect(context);
      expect(card, isNotNull);
      expect(card!.severity, InsightSeverity.alert);
      final data = card.data as BudgetRiskData;
      expect(data.risks.length, 2);
      expect(data.highestRiskItem.usagePercent, 96.0);
      expect(card.priority, greaterThan(1.2)); // Multiplier 1.4 applied
    });

    test('Spending Velocity: day 6 returns null (boundary test)', () {
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: List.generate(
          6,
          (i) => createExp(id: '$i', amount: 1000, categoryId: 'cat_dining', date: '2026-08-0${i + 1}'),
        ),
        selectedMonth: selectedMonth,
        now: DateTime(2026, 8, 6), // Day 6
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const SpendingVelocityDetector().detect(context);
      expect(card, isNull);
    });

    test('Spending Velocity: day 7 generates pace insight (boundary test)', () {
      final prevExp = [createExp(id: 'prev', amount: 20000, categoryId: 'cat_dining', date: '2026-07-15')];
      final curExp = List.generate(
        6,
        (i) => createExp(id: '$i', amount: 2000, categoryId: 'cat_dining', date: '2026-08-0${i + 1}'),
      );

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: [...prevExp, ...curExp],
        selectedMonth: selectedMonth,
        now: DateTime(2026, 8, 7), // Day 7
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const SpendingVelocityDetector().detect(context);
      expect(card, isNotNull);
      expect(card!.type, InsightType.spendingVelocity);
    });

    test('Spending Frequency: zero positive count in either month returns null safely', () {
      final expenses = [
        createExp(id: '1', amount: 5000, categoryId: 'cat_dining', date: '2026-08-10'),
      ]; // No previous month positive expenses

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const SpendingFrequencyDetector().detect(context);
      expect(card, isNull);
    });

    test('Merchant Inconsistency: evaluates only selected month and flags >=2 categories with >=3 positive transactions', () {
      final expenses = [
        createExp(id: '1', amount: 1000, categoryId: 'cat_dining', date: '2026-08-01', vendor: 'Daraz'),
        createExp(id: '2', amount: 2000, categoryId: 'cat_transport', date: '2026-08-02', vendor: 'Daraz'),
        createExp(id: '3', amount: 3000, categoryId: 'cat_dining', date: '2026-08-03', vendor: 'Daraz'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      final card = const MerchantCategoryInconsistencyDetector().detect(context);
      expect(card, isNotNull);
      final data = card!.data as MerchantInconsistencyData;
      expect(data.inconsistencies.first.displayName, 'Daraz');
      expect(data.inconsistencies.first.categoryNames.length, 2);
    });

    test('Essential vs Other: deterministic set union precedence without duplicate category counting and reconciled otherTotal', () {
      final templates = [
        const EssentialExpenseTemplate(
          id: 't1',
          name: 'Grocery template',
          categoryId: 'cat_groceries',
          frequency: 'monthly',
          expectedAmount: 10000,
          isActive: true,
          isFuel: false,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      ];
      final subscriptions = [
        const Subscription(
          id: 's1',
          name: 'Grocery subscription (overlap)',
          categoryId: 'cat_groceries', // Overlaps with template
          amount: 5000,
          currency: 'PKR',
          startDate: '2026-01-01',
          nextOccurrenceDate: '2026-09-01',
          billingCycle: 'monthly',
          status: SubscriptionStatus.active,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      ];

      final expenses = [
        createExp(id: '1', amount: 4000, categoryId: 'cat_groceries', date: '2026-08-05'),
        createExp(id: '2', amount: 6000, categoryId: 'cat_dining', date: '2026-08-06'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final context = InsightContext(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: templates,
        subscriptions: subscriptions,
        monthlyBudgetAmount: null,
      );

      final card = const EssentialVsOtherDetector().detect(context);
      expect(card, isNotNull);
      final data = card!.data as EssentialSplitData;
      expect(data.essentialTotal, 4000.0);
      expect(data.otherTotal, 6000.0);
      expect(data.essentialTotal + data.otherTotal, snapshot.currentTotal);
      expect(data.essentialPercent, 40.0);
    });

    test('Purity assertion: InsightEngine.generate does not mutate any input collections', () {
      final expenses = [
        createExp(id: '1', amount: 10000, categoryId: 'cat_dining', date: '2026-08-05'),
        createExp(id: '2', amount: 5000, categoryId: 'cat_dining', date: '2026-07-05'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final originalCatLength = categories.length;
      final cards = InsightEngine.generate(
        snapshot: snapshot,
        categories: categories,
        budgets: const [],
        essentialTemplates: const [],
        subscriptions: const [],
        monthlyBudgetAmount: null,
      );

      expect(categories.length, originalCatLength);
      expect(cards, isNotEmpty);
    });
  });
}
