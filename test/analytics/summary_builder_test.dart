import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/spending_analytics.dart';
import 'package:wallet_melt/src/analytics/summary_builder.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';

void main() {
  group('SummaryBuilder', () {
    final nowTime = DateTime(2026, 8, 24, 14, 30);
    final selectedMonth = DateTime(2026, 8);

    final categories = [
      const Category(
        id: 'cat_food',
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

    test('Top Categories filters out non-positive net categories and sorts with alphabetical tie-breaker', () {
      final expenses = [
        createExp(id: '1', amount: 5000, categoryId: 'cat_food', date: '2026-08-05'),
        createExp(id: '2', amount: 5000, categoryId: 'cat_transport', date: '2026-08-06'), // Same amount, 'Dining & Food' comes before 'Transport'
        createExp(id: '3', amount: 1000, categoryId: 'cat_utilities', date: '2026-08-07'),
        createExp(id: '4', amount: -2000, categoryId: 'cat_utilities', date: '2026-08-08'), // Net utilities = -1000 (filtered out)
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final summaries = SummaryBuilder.build(
        snapshot: snapshot,
        categories: categories,
      );

      expect(summaries.topCategories.length, 2);
      expect(summaries.topCategories[0].categoryId, 'cat_food');
      expect(summaries.topCategories[0].categoryName, 'Dining & Food');
      expect(summaries.topCategories[1].categoryId, 'cat_transport');
      expect(summaries.topCategories[1].categoryName, 'Transport');
    });

    test('Top Merchants filters out non-positive net merchants and sorts with alphabetical tie-breaker', () {
      final expenses = [
        createExp(id: '1', amount: 3000, categoryId: 'cat_food', date: '2026-08-01', vendor: 'Subway'),
        createExp(id: '2', amount: 3000, categoryId: 'cat_food', date: '2026-08-02', vendor: 'KFC'), // 'KFC' ties Subway, sorted alphabetically
        createExp(id: '3', amount: 500, categoryId: 'cat_food', date: '2026-08-03', vendor: 'Bad Store'),
        createExp(id: '4', amount: -600, categoryId: 'cat_food', date: '2026-08-04', vendor: 'Bad Store'), // Net = -100 (filtered)
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final summaries = SummaryBuilder.build(
        snapshot: snapshot,
        categories: categories,
      );

      expect(summaries.topMerchants.length, 2);
      expect(summaries.topMerchants[0].displayName, 'KFC');
      expect(summaries.topMerchants[1].displayName, 'Subway');
    });

    test('Largest Expenses strictly filters out refunds and sorts with ID tie-breaker', () {
      final expenses = [
        createExp(id: 'exp_1', amount: 1000, categoryId: 'cat_food', date: '2026-08-01'),
        createExp(id: 'exp_3', amount: 5000, categoryId: 'cat_food', date: '2026-08-02'),
        createExp(id: 'exp_2', amount: 5000, categoryId: 'cat_food', date: '2026-08-03'), // exp_2 ties exp_3, sorted exp_2 then exp_3
        createExp(id: 'exp_4', amount: -9000, categoryId: 'cat_food', date: '2026-08-04'), // Refund filtered
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final summaries = SummaryBuilder.build(
        snapshot: snapshot,
        categories: categories,
      );

      expect(summaries.largestExpenses.length, 3);
      expect(summaries.largestExpenses[0].id, 'exp_2');
      expect(summaries.largestExpenses[1].id, 'exp_3');
      expect(summaries.largestExpenses[2].id, 'exp_1');
    });
  });
}
