// ignore_for_file: avoid_print
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/insight_engine.dart';
import 'package:wallet_melt/src/analytics/spending_analytics.dart';
import 'package:wallet_melt/src/analytics/summary_builder.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/essential_expense.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/subscription.dart';

void main() {
  test('WalletMelt Insights V1 Performance Benchmark', () {
    print('========================================================================');
    print('              WalletMelt Insights V1 Performance Benchmark              ');
    print('========================================================================\n');

    final categories = _generateCategories();
    final budgets = _generateBudgets(categories);
    final essentialTemplates = _generateEssentialTemplates();
    final subscriptions = _generateSubscriptions();

    final datasetSizes = [100, 1000, 10000, 50000, 100000];
    final nowTime = DateTime(2026, 8, 24, 12, 0);
    final selectedMonth = DateTime(2026, 8);

    print('| Dataset (N) | Snapshot (ms) | Insight Engine (ms) | Summary Builder (ms) | Full Pipeline (ms) |');
    print('|:-----------:|:-------------:|:-------------------:|:--------------------:|:------------------:|');

    for (final n in datasetSizes) {
      final expenses = _generateDeterministicExpenses(n);

      // Warmup
      for (var i = 0; i < 2; i++) {
        final snap = SpendingAnalytics.buildSnapshot(
          expenses: expenses,
          selectedMonth: selectedMonth,
          now: nowTime,
          currency: 'PKR',
        );
        InsightEngine.generate(
          snapshot: snap,
          categories: categories,
          budgets: budgets,
          essentialTemplates: essentialTemplates,
          subscriptions: subscriptions,
          monthlyBudgetAmount: 100000,
        );
        SummaryBuilder.build(
          snapshot: snap,
          categories: categories,
        );
      }

      // Benchmark runs
      const iterations = 5;
      double totalSnapshotMicros = 0;
      double totalInsightMicros = 0;
      double totalSummaryMicros = 0;
      double totalFullPipelineMicros = 0;

      for (var i = 0; i < iterations; i++) {
        final fullSw = Stopwatch()..start();

        final snapSw = Stopwatch()..start();
        final snapshot = SpendingAnalytics.buildSnapshot(
          expenses: expenses,
          selectedMonth: selectedMonth,
          now: nowTime,
          currency: 'PKR',
        );
        snapSw.stop();

        final insightSw = Stopwatch()..start();
        InsightEngine.generate(
          snapshot: snapshot,
          categories: categories,
          budgets: budgets,
          essentialTemplates: essentialTemplates,
          subscriptions: subscriptions,
          monthlyBudgetAmount: 100000,
        );
        insightSw.stop();

        final summarySw = Stopwatch()..start();
        SummaryBuilder.build(
          snapshot: snapshot,
          categories: categories,
        );
        summarySw.stop();

        fullSw.stop();

        totalSnapshotMicros += snapSw.elapsedMicroseconds;
        totalInsightMicros += insightSw.elapsedMicroseconds;
        totalSummaryMicros += summarySw.elapsedMicroseconds;
        totalFullPipelineMicros += fullSw.elapsedMicroseconds;
      }

      final avgSnapMs = (totalSnapshotMicros / iterations) / 1000.0;
      final avgInsightMs = (totalInsightMicros / iterations) / 1000.0;
      final avgSummaryMs = (totalSummaryMicros / iterations) / 1000.0;
      final avgFullMs = (totalFullPipelineMicros / iterations) / 1000.0;

      print('| ${n.toString().padLeft(11)} | ${avgSnapMs.toStringAsFixed(3).padLeft(13)} | ${avgInsightMs.toStringAsFixed(3).padLeft(19)} | ${avgSummaryMs.toStringAsFixed(3).padLeft(20)} | ${avgFullMs.toStringAsFixed(3).padLeft(18)} |');
    }

    print('\nBenchmark complete.');
  });
}

List<Category> _generateCategories() {
  const names = [
    'Grocery', 'Dining', 'Fuel', 'Shopping', 'Utilities',
    'Entertainment', 'Healthcare', 'Travel', 'Education', 'Personal'
  ];
  return List.generate(names.length, (i) {
    final id = 'cat_${names[i].toLowerCase()}';
    return Category(
      id: id,
      name: names[i],
      icon: 'category',
      color: '#4F46E5',
      isDefault: true,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    );
  });
}

List<CategoryBudget> _generateBudgets(List<Category> categories) {
  return categories.take(5).map((c) {
    return CategoryBudget(
      id: 'b_${c.id}',
      categoryId: c.id,
      amount: 30000,
      month: '2026-08',
      currency: 'PKR',
      createdAt: '2026-08-01',
      updatedAt: '2026-08-01',
    );
  }).toList();
}

List<EssentialExpenseTemplate> _generateEssentialTemplates() {
  return [
    const EssentialExpenseTemplate(
      id: 'tmpl_1',
      name: 'Electricity Bill',
      expectedAmount: 15000,
      categoryId: 'cat_utilities',
      frequency: 'monthly',
      expectedDay: 10,
      isActive: true,
      isFuel: false,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
    const EssentialExpenseTemplate(
      id: 'tmpl_2',
      name: 'Monthly Fuel Allowance',
      expectedAmount: 20000,
      categoryId: 'cat_fuel',
      frequency: 'monthly',
      expectedDay: 1,
      isActive: true,
      isFuel: false,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
  ];
}

List<Subscription> _generateSubscriptions() {
  return [
    const Subscription(
      id: 'sub_1',
      name: 'Internet Fiber',
      amount: 4500,
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
}

List<Expense> _generateDeterministicExpenses(int count) {
  final rng = Random(42);
  final categories = [
    'cat_grocery', 'cat_dining', 'cat_fuel', 'cat_shopping', 'cat_utilities',
    'cat_entertainment', 'cat_healthcare', 'cat_travel', 'cat_education', 'cat_personal'
  ];
  final vendors = [
    'Subway', 'KFC', 'Shell Fuel', 'Carrefour', 'Amazon',
    'Netflix', 'Pharmacy Care', 'Uber', 'Coursera', 'SuperMart'
  ];

  return List.generate(count, (i) {
    final isPreviousMonth = (i % 3 == 0);
    final day = 1 + (rng.nextInt(23)); // 1 to 24 (before nowTime)
    final monthStr = isPreviousMonth ? '2026-07' : '2026-08';
    final dayStr = day.toString().padLeft(2, '0');
    final date = '$monthStr-$dayStr';

    final isRefund = (i % 25 == 0);
    final baseAmount = 100.0 + rng.nextInt(5000);
    final amount = isRefund ? -baseAmount : baseAmount;

    final catId = categories[rng.nextInt(categories.length)];
    final vendor = vendors[rng.nextInt(vendors.length)];

    return Expense(
      id: 'exp_$i',
      amount: amount,
      currency: 'PKR',
      categoryId: catId,
      title: 'Expense $i',
      date: date,
      vendor: vendor,
      isRecurring: false,
      createdAt: date,
      updatedAt: date,
    );
  });
}
