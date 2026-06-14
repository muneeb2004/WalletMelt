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
  final current = expenses
      .where((expense) => isSameMonth(parseIsoDate(expense.date), month))
      .toList();
  final previousMonth = DateTime(month.year, month.month - 1);
  final previous = expenses
      .where(
          (expense) => isSameMonth(parseIsoDate(expense.date), previousMonth))
      .toList();
  final total = current.fold<double>(0, (sum, expense) => sum + expense.amount);
  final budgetByCategory = {
    for (final budget in budgets) budget.categoryId: budget
  };

  final categorySpend = categories
      .map((category) {
        final categoryTotal = current
            .where((expense) => expense.categoryId == category.id)
            .fold<double>(0, (sum, expense) => sum + expense.amount);
        return CategorySpend(
          category: category,
          total: categoryTotal,
          percentOfTotal: total == 0 ? 0 : categoryTotal / total,
          budget: budgetByCategory[category.id],
        );
      })
      .where((spend) => spend.total > 0 || spend.budget != null)
      .sorted((a, b) => b.total.compareTo(a.total));

  final groceryTotal = current
      .where((expense) => expense.categoryId == 'grocery')
      .fold<double>(0, (sum, expense) => sum + expense.amount);
  final utilitiesIds = {
    'electricity',
    'gas',
    'internet',
    'water',
    'maintenance'
  };
  final utilitiesTotal = current
      .where((expense) => utilitiesIds.contains(expense.categoryId))
      .fold<double>(0, (sum, expense) => sum + expense.amount);

  return MonthlyInsights(
    total: total,
    categorySpend: categorySpend,
    recentExpenses: current.take(5).toList(),
    groceryTotal: groceryTotal,
    utilitiesTotal: utilitiesTotal,
    previousMonthTotal: previous.isEmpty
        ? null
        : previous.fold<double>(0, (sum, expense) => sum + expense.amount),
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
