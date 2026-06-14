import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../types/budget.dart';

class BudgetRepository {
  BudgetRepository(this._db);

  final Database _db;
  final _uuid = const Uuid();

  Future<List<CategoryBudget>> listForMonth(String month) async {
    final rows = await _db.query(
      'category_budgets',
      where: 'month = ?',
      whereArgs: [month],
      orderBy: 'categoryId ASC',
    );
    return rows.map(CategoryBudget.fromMap).toList();
  }

  Future<void> upsert({
    required String categoryId,
    required double amount,
    required String currency,
    required String month,
  }) async {
    final now = DateTime.now().toIso8601String();
    final budget = CategoryBudget(
      id: _uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      currency: currency,
      month: month,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(
      'category_budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String categoryId, String month) async {
    await _db.delete(
      'category_budgets',
      where: 'categoryId = ? AND month = ?',
      whereArgs: [categoryId, month],
    );
  }
}
