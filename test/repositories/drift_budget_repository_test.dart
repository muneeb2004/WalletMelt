import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';

void main() {
  test('upserts, lists, sorts, and deletes category budgets by month',
      () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftBudgetRepository(db);

    await repository.upsert(
        categoryId: 'grocery',
        amount: 30000,
        currency: 'PKR',
        month: '2026-06');
    await repository.upsert(
        categoryId: 'electricity',
        amount: 12000,
        currency: 'PKR',
        month: '2026-06');

    var budgets = await repository.listForMonth('2026-06');
    expect(
        budgets.map((budget) => budget.categoryId), ['electricity', 'grocery']);

    await repository.upsert(
        categoryId: 'grocery',
        amount: 35000,
        currency: 'PKR',
        month: '2026-06');
    budgets = await repository.listForMonth('2026-06');
    expect(budgets.where((budget) => budget.categoryId == 'grocery'),
        hasLength(1));
    expect(
        budgets.singleWhere((budget) => budget.categoryId == 'grocery').amount,
        35000);

    await repository.delete('grocery', '2026-06');
    budgets = await repository.listForMonth('2026-06');
    expect(budgets.map((budget) => budget.categoryId), ['electricity']);
  });
}
