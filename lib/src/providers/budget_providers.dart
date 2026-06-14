import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../types/budget.dart';
import 'repository_providers.dart';

class BudgetLookup {
  const BudgetLookup({required this.month, required this.categoryId});

  final String month;
  final String categoryId;

  @override
  bool operator ==(Object other) {
    return other is BudgetLookup &&
        other.month == month &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(month, categoryId);
}

final monthlyBudgetsProvider =
    FutureProvider.family<List<CategoryBudget>, String>((ref, month) async {
  final repository = await ref.watch(driftBudgetRepositoryProvider.future);
  return repository.listForMonth(month);
});

final budgetByCategoryProvider =
    FutureProvider.family<CategoryBudget?, BudgetLookup>((ref, lookup) async {
  final budgets = await ref.watch(monthlyBudgetsProvider(lookup.month).future);
  for (final budget in budgets) {
    if (budget.categoryId == lookup.categoryId) return budget;
  }
  return null;
});
