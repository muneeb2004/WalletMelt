import 'package:collection/collection.dart';

import '../types/budget.dart';
import '../types/category.dart';
import '../types/expense.dart';
import 'date_utils.dart';

class CategorySpend {
  const CategorySpend(
      {required this.category,
      required this.total,
      required this.percentOfTotal,
      this.budget});

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

MonthlyInsights buildMonthlyInsights({
  required List<Expense> expenses,
  required List<Category> categories,
  required List<CategoryBudget> budgets,
  required DateTime month,
}) {
  final previousMonth = DateTime(month.year, month.month - 1);
  final categoryTotals = <String, double>{};
  double currentTotal = 0;
  double previousTotal = 0;
  double groceryTotal = 0;
  const utilitiesIds = {'electricity', 'gas', 'internet', 'water', 'maintenance'};
  double utilitiesTotal = 0;
  final currentExpenses = <Expense>[];
  bool hasPreviousMonth = false;

  for (final expense in expenses) {
    DateTime date;
    try {
      date = parseIsoDate(expense.date);
    } catch (_) {
      continue;
    }
    if (isSameMonth(date, month)) {
      currentExpenses.add(expense);
      currentTotal += expense.amount;
      categoryTotals[expense.categoryId] =
          (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      if (expense.categoryId == 'grocery') groceryTotal += expense.amount;
      if (utilitiesIds.contains(expense.categoryId)) {
        utilitiesTotal += expense.amount;
      }
    } else if (isSameMonth(date, previousMonth)) {
      previousTotal += expense.amount;
      hasPreviousMonth = true;
    }
  }

  final budgetByCategory = {
    for (final budget in budgets) budget.categoryId: budget
  };

  final categorySpend = categories
      .map((category) {
        final total = categoryTotals[category.id] ?? 0;
        return CategorySpend(
          category: category,
          total: total,
          percentOfTotal: currentTotal == 0 ? 0 : total / currentTotal,
          budget: budgetByCategory[category.id],
        );
      })
      .where((spend) => spend.total > 0 || spend.budget != null)
      .sorted((a, b) => b.total.compareTo(a.total));

  return MonthlyInsights(
    total: currentTotal,
    categorySpend: categorySpend,
    recentExpenses: currentExpenses.take(5).toList(),
    groceryTotal: groceryTotal,
    utilitiesTotal: utilitiesTotal,
    previousMonthTotal: hasPreviousMonth ? previousTotal : null,
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
