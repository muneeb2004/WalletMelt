import 'package:collection/collection.dart';

import '../analytics/analytics_snapshot.dart';
import '../analytics/spending_analytics.dart';
import '../types/budget.dart';
import '../types/category.dart';
import '../types/expense.dart';
import 'date_utils.dart';

class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.total,
    required this.percentOfTotal,
    this.budget,
  });

  final Category category;
  final double total;
  final double percentOfTotal;
  final CategoryBudget? budget;

  bool get isOverBudget => budget != null && total > budget!.amount;
}

class MonthlyInsights {
  const MonthlyInsights({
    required this.total,
    required this.categorySpend,
    required this.recentExpenses,
    required this.groceryTotal,
    required this.utilitiesTotal,
    required this.previousMonthTotal,
  });

  final double total;
  final List<CategorySpend> categorySpend;
  final List<Expense> recentExpenses;
  final double groceryTotal;
  final double utilitiesTotal;
  final double? previousMonthTotal;

  CategorySpend? get highestCategory =>
      categorySpend.isEmpty ? null : categorySpend.first;

  double? get monthOverMonthDelta {
    final previous = previousMonthTotal;
    if (previous == null || previous == 0) return null;
    return ((total - previous) / previous) * 100;
  }
}

/// Builds [MonthlyInsights] by generating a canonical [SpendingAnalyticsSnapshot].
MonthlyInsights buildMonthlyInsights({
  required List<Expense> expenses,
  required List<Category> categories,
  required List<CategoryBudget> budgets,
  required DateTime month,
  DateTime? now,
  String currency = 'PKR',
}) {
  final nowTime = now ?? DateTime.now();
  final snapshot = SpendingAnalytics.buildSnapshot(
    expenses: expenses,
    selectedMonth: month,
    now: nowTime,
    currency: currency,
  );

  return buildMonthlyInsightsFromSnapshot(
    snapshot: snapshot,
    categories: categories,
    budgets: budgets,
  );
}

/// Adapts a precomputed [SpendingAnalyticsSnapshot] into [MonthlyInsights].
MonthlyInsights buildMonthlyInsightsFromSnapshot({
  required SpendingAnalyticsSnapshot snapshot,
  required List<Category> categories,
  required List<CategoryBudget> budgets,
}) {
  const utilitiesIds = {
    'electricity',
    'gas',
    'internet',
    'water',
    'maintenance',
  };
  final budgetByCategory = {
    for (final budget in budgets) budget.categoryId: budget,
  };

  final denominator = snapshot.currentTotal > 0
      ? snapshot.currentTotal
      : snapshot.currentPositiveTotal;

  final categorySpend = categories
      .map((category) {
        final total = snapshot.currentByCategory[category.id] ?? 0.0;
        final pct = denominator > 0
            ? ((total > 0 ? total : 0.0) / denominator).clamp(0.0, 1.0)
            : 0.0;
        return CategorySpend(
          category: category,
          total: total,
          percentOfTotal: pct,
          budget: budgetByCategory[category.id],
        );
      })
      .where((spend) => spend.total > 0 || spend.budget != null)
      .sorted((a, b) => b.total.compareTo(a.total));

  double groceryTotal = snapshot.currentByCategory['grocery'] ?? 0.0;
  double utilitiesTotal = 0.0;
  for (final id in utilitiesIds) {
    utilitiesTotal += snapshot.currentByCategory[id] ?? 0.0;
  }

  // Chronologically sorted recent expenses with deterministic id ASC tie-breaker
  final recentExpenses = [...snapshot.currentExpenses]
    ..sort((a, b) {
      final dateCmp = parseIsoDate(b.date).compareTo(parseIsoDate(a.date));
      if (dateCmp != 0) return dateCmp;
      return a.id.compareTo(b.id);
    });

  return MonthlyInsights(
    total: snapshot.currentTotal,
    categorySpend: categorySpend,
    recentExpenses: recentExpenses.take(5).toList(),
    groceryTotal: groceryTotal,
    utilitiesTotal: utilitiesTotal,
    previousMonthTotal:
        snapshot.previousExpenses.isNotEmpty ? snapshot.previousTotal : null,
  );
}

Map<String, List<Expense>> groupExpensesByMonth(List<Expense> expenses) {
  final grouped = <String, List<Expense>>{};
  for (final expense in expenses) {
    final key = monthKey(parseIsoDate(expense.date));
    grouped.putIfAbsent(key, () => []).add(expense);
  }
  return grouped;
}
