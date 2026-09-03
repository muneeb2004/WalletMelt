import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_monthly_budget_repository.dart';

void main() {
  late WalletMeltDatabase database;
  late DriftMonthlyBudgetRepository repository;

  setUp(() {
    database = WalletMeltDatabase.memory();
    repository = DriftMonthlyBudgetRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftMonthlyBudgetRepository', () {
    test('getForMonth returns null when no budget exists for month', () async {
      final budget = await repository.getForMonth('2026-06');
      expect(budget, isNull);
    });

    test('upsert creates new monthly budget and getForMonth fetches it', () async {
      await repository.upsert(
        month: '2026-06',
        amount: 3500.0,
        currency: 'USD',
      );

      final budget = await repository.getForMonth('2026-06');
      expect(budget, isNotNull);
      expect(budget!.month, '2026-06');
      expect(budget.amount, 3500.0);
      expect(budget.currency, 'USD');
    });

    test('upsert updates existing monthly budget for the same month', () async {
      await repository.upsert(
        month: '2026-07',
        amount: 2000.0,
        currency: 'USD',
      );

      var budget = await repository.getForMonth('2026-07');
      expect(budget!.amount, 2000.0);

      // Update amount
      await repository.upsert(
        month: '2026-07',
        amount: 2750.0,
        currency: 'EUR',
      );

      budget = await repository.getForMonth('2026-07');
      expect(budget!.amount, 2750.0);
      expect(budget.currency, 'EUR');
    });

    test('listAll returns all monthly budgets ordered or recorded', () async {
      await repository.upsert(month: '2026-05', amount: 1500.0, currency: 'USD');
      await repository.upsert(month: '2026-06', amount: 2500.0, currency: 'USD');
      await repository.upsert(month: '2026-07', amount: 3500.0, currency: 'USD');

      final all = await repository.listAll();
      expect(all.length, 3);
      expect(all.map((b) => b.month).toList(), containsAll(['2026-05', '2026-06', '2026-07']));
    });

    test('delete removes the monthly budget for the given month', () async {
      await repository.upsert(month: '2026-08', amount: 4000.0, currency: 'USD');
      expect(await repository.getForMonth('2026-08'), isNotNull);

      await repository.delete('2026-08');
      expect(await repository.getForMonth('2026-08'), isNull);
    });
  });
}
