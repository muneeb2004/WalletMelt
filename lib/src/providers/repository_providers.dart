import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/drift/drift_budget_repository.dart';
import '../data/repositories/drift/drift_category_repository.dart';
import '../data/repositories/drift/drift_expense_repository.dart';
import '../data/repositories/drift/drift_item_repository.dart';
import '../data/repositories/drift/drift_receipt_repository.dart';
import '../data/repositories/drift/drift_store_repository.dart';
import '../data/repositories/expense_repository.dart';
import 'database_providers.dart';

final categoryRepositoryProvider =
    FutureProvider<CategoryRepository>((ref) async {
  final database = await ref.watch(sqfliteDatabaseProvider.future);
  return CategoryRepository(database);
});

final expenseRepositoryProvider =
    FutureProvider<ExpenseRepository>((ref) async {
  final database = await ref.watch(sqfliteDatabaseProvider.future);
  return ExpenseRepository(database);
});

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  final database = await ref.watch(sqfliteDatabaseProvider.future);
  return BudgetRepository(database);
});

final driftCategoryRepositoryProvider =
    FutureProvider<DriftCategoryRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftCategoryRepository(database);
});

final driftExpenseRepositoryProvider =
    FutureProvider<DriftExpenseRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftExpenseRepository(database);
});

final driftBudgetRepositoryProvider =
    FutureProvider<DriftBudgetRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftBudgetRepository(database);
});

final driftItemRepositoryProvider =
    FutureProvider<DriftItemRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftItemRepository(database);
});

final driftStoreRepositoryProvider =
    FutureProvider<DriftStoreRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftStoreRepository(database);
});

final driftReceiptRepositoryProvider =
    FutureProvider<DriftReceiptRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftReceiptRepository(database);
});
