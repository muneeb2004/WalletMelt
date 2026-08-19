import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/providers/repository_providers.dart';
import 'package:wallet_melt/src/providers/database_providers.dart';
import 'security_providers.dart';

final appStateProvider = FutureProvider<AppState>((ref) async {
  final categoryRepo = await ref.watch(driftCategoryRepositoryProvider.future);
  final budgetRepo = await ref.watch(driftBudgetRepositoryProvider.future);
  final expenseRepo = await ref.watch(driftExpenseRepositoryProvider.future);
  final debtRepo = await ref.watch(driftDebtRepositoryProvider.future);
  final groceryTemplateRepo = await ref.watch(driftGroceryTemplateRepositoryProvider.future);
  final subscriptionRepo = await ref.watch(driftSubscriptionRepositoryProvider.future);
  final payeeRepo = await ref.watch(driftPayeeRepositoryProvider.future);
  final essentialRepo = await ref.watch(driftEssentialExpenseRepositoryProvider.future);
  final fuelRepo = await ref.watch(driftFuelRepositoryProvider.future);
  final database = await ref.watch(walletMeltDatabaseProvider.future);

  final appState = AppState(
    driftCategoryRepository: categoryRepo,
    driftBudgetRepository: budgetRepo,
    driftExpenseRepository: expenseRepo,
    driftDebtRepository: debtRepo,
    driftGroceryTemplateRepository: groceryTemplateRepo,
    driftSubscriptionRepository: subscriptionRepo,
    driftPayeeRepository: payeeRepo,
    driftEssentialExpenseRepository: essentialRepo,
    driftFuelRepository: fuelRepo,
    driftDatabase: database,
  );

  await appState.initialize();

  // Load PIN settings securely before startup completes
  final pinLockController = ref.read(pinLockControllerProvider);
  await pinLockController.initialize();

  return appState;
});

