import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/drift/drift_budget_repository.dart';
import '../data/repositories/drift/drift_category_repository.dart';
import '../data/repositories/drift/drift_expense_repository.dart';
import '../data/repositories/drift/drift_item_repository.dart';
import '../data/repositories/drift/drift_receipt_repository.dart';
import '../data/repositories/drift/drift_store_repository.dart';
import '../data/repositories/drift/drift_debt_repository.dart';
import '../data/repositories/drift/drift_grocery_template_repository.dart';
import '../data/repositories/drift/drift_subscription_repository.dart';
import '../data/repositories/drift/drift_payee_repository.dart';
import '../data/repositories/drift/drift_essential_expense_repository.dart';
import '../data/repositories/drift/drift_fuel_repository.dart';
import 'database_providers.dart';

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

final driftDebtRepositoryProvider =
    FutureProvider<DriftDebtRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftDebtRepository(database);
});

final driftGroceryTemplateRepositoryProvider =
    FutureProvider<DriftGroceryTemplateRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftGroceryTemplateRepository(database);
});

final driftSubscriptionRepositoryProvider =
    FutureProvider<DriftSubscriptionRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftSubscriptionRepository(database);
});

final driftPayeeRepositoryProvider =
    FutureProvider<DriftPayeeRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftPayeeRepository(database);
});

final driftEssentialExpenseRepositoryProvider =
    FutureProvider<DriftEssentialExpenseRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftEssentialExpenseRepository(database);
});

final driftFuelRepositoryProvider =
    FutureProvider<DriftFuelRepository>((ref) async {
  final database = await ref.watch(walletMeltDatabaseProvider.future);
  return DriftFuelRepository(database);
});
