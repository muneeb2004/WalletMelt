import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../../../types/budget.dart' as domain;

class DriftBudgetRepository {
  DriftBudgetRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  Future<List<domain.CategoryBudget>> listForMonth(String month) async {
    final rows = await (_db.select(_db.categoryBudgets)
          ..where((budget) => budget.month.equals(month))
          ..orderBy([
            (budget) => OrderingTerm(expression: budget.categoryId),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<domain.CategoryBudget>> listAll() async {
    final rows = await (_db.select(_db.categoryBudgets)
          ..orderBy([
            (budget) => OrderingTerm(expression: budget.month),
            (budget) => OrderingTerm(expression: budget.categoryId),
            (budget) => OrderingTerm(expression: budget.id),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> upsert({
    required String categoryId,
    required double amount,
    required String currency,
    required String month,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.customStatement(
      '''
INSERT OR REPLACE INTO category_budgets (id, categoryId, amount, currency, month, createdAt, updatedAt)
VALUES (?, ?, ?, ?, ?, ?, ?);
''',
      [_uuid.v4(), categoryId, amount, currency, month, now, now],
    );
  }

  Future<void> delete(String categoryId, String month) async {
    await (_db.delete(_db.categoryBudgets)
          ..where((budget) =>
              budget.categoryId.equals(categoryId) &
              budget.month.equals(month)))
        .go();
  }

  domain.CategoryBudget _toDomain(local.CategoryBudget row) {
    return domain.CategoryBudget(
      id: row.id,
      categoryId: row.categoryId,
      amount: row.amount,
      currency: row.currency,
      month: row.month,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
