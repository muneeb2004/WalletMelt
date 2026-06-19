import 'dart:convert';

import '../../types/budget.dart';
import '../../types/category.dart';
import '../../types/expense.dart';
import '../../types/grocery_item.dart';
import '../../types/settings.dart';

class WalletMeltJsonBackupEncoder {
  const WalletMeltJsonBackupEncoder();

  static const int formatVersion = 1;
  static const String format = 'walletmelt.local_json_backup';

  String encode({
    required Iterable<Expense> expenses,
    required Iterable<GroceryItem> groceryItems,
    required Iterable<Category> categories,
    required Iterable<CategoryBudget> budgets,
    required WalletMeltSettings settings,
    required DateTime exportedAt,
    String? appVersion,
  }) {
    final backup = <String, Object?>{
      'metadata': <String, Object?>{
        'format': format,
        'format_version': formatVersion,
        'app_version': appVersion,
        'exported_at': exportedAt.toIso8601String(),
        'includes': <String>[
          'expenses',
          'grocery_items',
          'categories',
          'budgets',
          'settings',
        ],
      },
      'expenses': _sortedExpenses(expenses).map(_expenseToJson).toList(),
      'grocery_items':
          _sortedGroceryItems(groceryItems).map(_groceryItemToJson).toList(),
      'categories': _sortedCategories(categories).map(_categoryToJson).toList(),
      'budgets': _sortedBudgets(budgets).map(_budgetToJson).toList(),
      'settings': _settingsToJson(settings),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  List<Expense> _sortedExpenses(Iterable<Expense> expenses) {
    final sorted = expenses.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return sorted;
  }

  List<Category> _sortedCategories(Iterable<Category> categories) {
    final sorted = categories.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return sorted;
  }

  List<GroceryItem> _sortedGroceryItems(Iterable<GroceryItem> groceryItems) {
    final sorted = groceryItems.toList()
      ..sort((left, right) {
        final expenseCompare = left.expenseId.compareTo(right.expenseId);
        if (expenseCompare != 0) return expenseCompare;
        final createdCompare = left.createdAt.compareTo(right.createdAt);
        if (createdCompare != 0) return createdCompare;
        return left.id.compareTo(right.id);
      });
    return sorted;
  }

  List<CategoryBudget> _sortedBudgets(Iterable<CategoryBudget> budgets) {
    final sorted = budgets.toList()
      ..sort((left, right) {
        final monthCompare = left.month.compareTo(right.month);
        if (monthCompare != 0) return monthCompare;
        final categoryCompare = left.categoryId.compareTo(right.categoryId);
        if (categoryCompare != 0) return categoryCompare;
        return left.id.compareTo(right.id);
      });
    return sorted;
  }

  Map<String, Object?> _expenseToJson(Expense expense) {
    return <String, Object?>{
      'id': expense.id,
      'amount': expense.amount,
      'currency': expense.currency,
      'category_id': expense.categoryId,
      'title': expense.title,
      'vendor': expense.vendor,
      'date': expense.date,
      'notes': expense.notes,
      'receipt_image_uri': expense.receiptImageUri,
      'is_recurring': expense.isRecurring,
      'recurrence_frequency': expense.recurrenceFrequency?.name,
      'created_at': expense.createdAt,
      'updated_at': expense.updatedAt,
      'deleted_at': expense.deletedAt,
    };
  }

  Map<String, Object?> _categoryToJson(Category category) {
    return <String, Object?>{
      'id': category.id,
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
      'is_default': category.isDefault,
      'created_at': category.createdAt,
      'updated_at': category.updatedAt,
    };
  }

  Map<String, Object?> _groceryItemToJson(GroceryItem item) {
    return <String, Object?>{
      'id': item.id,
      'expense_id': item.expenseId,
      'name': item.name,
      'amount': item.amount,
      'created_at': item.createdAt,
    };
  }

  Map<String, Object?> _budgetToJson(CategoryBudget budget) {
    return <String, Object?>{
      'id': budget.id,
      'category_id': budget.categoryId,
      'amount': budget.amount,
      'currency': budget.currency,
      'month': budget.month,
      'created_at': budget.createdAt,
      'updated_at': budget.updatedAt,
    };
  }

  Map<String, Object?> _settingsToJson(WalletMeltSettings settings) {
    return <String, Object?>{
      'currency': settings.currency,
      'theme_preference': settings.themePreference.name,
      'has_completed_onboarding': settings.hasCompletedOnboarding,
      'last_exported_at': settings.lastExportedAt,
      'monthly_budget_amount': settings.monthlyBudgetAmount,
    };
  }
}
