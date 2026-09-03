import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../../../types/monthly_budget.dart' as domain;

class DriftMonthlyBudgetRepository {
  DriftMonthlyBudgetRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  Future<domain.MonthlyBudget?> getForMonth(String month) async {
    final row = await (_db.select(_db.monthlyBudgets)
          ..where((b) => b.month.equals(month)))
        .getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  Future<List<domain.MonthlyBudget>> listAll() async {
    final rows = await (_db.select(_db.monthlyBudgets)
          ..orderBy([
            (b) => OrderingTerm(expression: b.month),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> upsert({
    required String month,
    required double amount,
    required String currency,
  }) async {
    final now = DateTime.now().toIso8601String();
    final minorUnits = (amount * 100).round();
    await _db.customStatement(
      '''
INSERT INTO monthly_budgets (id, month, amount, amountMinorUnits, currency, createdAt, updatedAt)
VALUES (?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(month) DO UPDATE SET
  amount = excluded.amount,
  amountMinorUnits = excluded.amountMinorUnits,
  currency = excluded.currency,
  updatedAt = excluded.updatedAt;
''',
      [_uuid.v4(), month, amount, minorUnits, currency, now, now],
    );
  }

  Future<void> delete(String month) async {
    await (_db.delete(_db.monthlyBudgets)
          ..where((b) => b.month.equals(month)))
        .go();
  }

  domain.MonthlyBudget _toDomain(local.MonthlyBudget row) {
    return domain.MonthlyBudget(
      id: row.id,
      month: row.month,
      amount: row.amount,
      currency: row.currency,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
