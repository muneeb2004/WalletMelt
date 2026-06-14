import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/utils/insights.dart';

void main() {
  test('buildMonthlyInsights calculates totals, highest category, utilities, grocery, and budget state', () {
    final now = DateTime(2026, 6, 13).toIso8601String();
    final categories = [
      Category(id: 'grocery', name: 'Grocery', icon: 'shopping_basket', color: '#8FD6B5', isDefault: true, createdAt: now, updatedAt: now),
      Category(id: 'electricity', name: 'Electricity', icon: 'bolt', color: '#F4B740', isDefault: true, createdAt: now, updatedAt: now),
      Category(id: 'rent', name: 'Rent', icon: 'home', color: '#A88CC2', isDefault: true, createdAt: now, updatedAt: now),
    ];
    final expenses = [
      _expense(id: '1', amount: 5000, categoryId: 'grocery', date: DateTime(2026, 6, 3)),
      _expense(id: '2', amount: 6500, categoryId: 'electricity', date: DateTime(2026, 6, 5)),
      _expense(id: '3', amount: 3000, categoryId: 'grocery', date: DateTime(2026, 5, 5)),
    ];
    final budgets = [
      CategoryBudget(id: 'b1', categoryId: 'electricity', amount: 4000, currency: 'PKR', month: '2026-06', createdAt: now, updatedAt: now),
    ];

    final insights = buildMonthlyInsights(
      expenses: expenses,
      categories: categories,
      budgets: budgets,
      month: DateTime(2026, 6),
    );

    expect(insights.total, 11500);
    expect(insights.highestCategory?.category.id, 'electricity');
    expect(insights.groceryTotal, 5000);
    expect(insights.utilitiesTotal, 6500);
    expect(insights.previousMonthTotal, 3000);
    expect(insights.highestCategory?.isOverBudget, isTrue);
  });
}

Expense _expense({
  required String id,
  required double amount,
  required String categoryId,
  required DateTime date,
}) {
  final now = DateTime(2026, 6, 13).toIso8601String();
  return Expense(
    id: id,
    amount: amount,
    currency: 'PKR',
    categoryId: categoryId,
    title: 'Expense $id',
    date: date.toIso8601String(),
    isRecurring: false,
    createdAt: now,
    updatedAt: now,
  );
}
