import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/providers/budget_providers.dart';
import 'package:wallet_melt/src/providers/database_providers.dart';
import 'package:wallet_melt/src/providers/repository_providers.dart';

void main() {
  test('monthlyBudgetsProvider returns V1-compatible sorted budgets', () async {
    final container = _containerWithMemoryDatabase();
    addTearDown(container.dispose);

    final repository = await container.read(driftBudgetRepositoryProvider.future);
    await repository.upsert(categoryId: 'grocery', amount: 30000, currency: 'PKR', month: '2026-06');
    await repository.upsert(categoryId: 'electricity', amount: 12000, currency: 'PKR', month: '2026-06');

    container.invalidate(monthlyBudgetsProvider('2026-06'));
    final budgets = await container.read(monthlyBudgetsProvider('2026-06').future);

    expect(budgets.map((budget) => budget.categoryId), ['electricity', 'grocery']);
    expect(budgets.singleWhere((budget) => budget.categoryId == 'grocery').amount, 30000);
  });

  test('budgetByCategoryProvider resolves and reflects delete after invalidation', () async {
    final container = _containerWithMemoryDatabase();
    addTearDown(container.dispose);

    final repository = await container.read(driftBudgetRepositoryProvider.future);
    await repository.upsert(categoryId: 'grocery', amount: 30000, currency: 'PKR', month: '2026-06');

    const lookup = BudgetLookup(month: '2026-06', categoryId: 'grocery');
    container.invalidate(monthlyBudgetsProvider('2026-06'));
    var budget = await container.read(budgetByCategoryProvider(lookup).future);
    expect(budget?.amount, 30000);

    await repository.delete('grocery', '2026-06');
    container
      ..invalidate(monthlyBudgetsProvider('2026-06'))
      ..invalidate(budgetByCategoryProvider(lookup));
    budget = await container.read(budgetByCategoryProvider(lookup).future);
    expect(budget, isNull);
  });
}

ProviderContainer _containerWithMemoryDatabase() {
  return ProviderContainer(
    overrides: [
      walletMeltDatabaseProvider.overrideWith((ref) async {
        final database = WalletMeltDatabase(NativeDatabase.memory());
        ref.onDispose(database.close);
        return database;
      }),
    ],
  );
}
