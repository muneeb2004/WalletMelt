import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../types/expense.dart';
import '../../types/grocery_item.dart';

class ExpenseDraft {
  ExpenseDraft({
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.title,
    required this.date,
    this.vendor,
    this.notes,
    this.receiptImageUri,
    this.groceryItems = const [],
    this.subtotalAmount,
    this.taxAmount,
  });

  final double amount;
  final String currency;
  final String categoryId;
  final String title;
  final DateTime date;
  final String? vendor;
  final String? notes;
  final String? receiptImageUri;
  final List<GroceryItemDraft> groceryItems;
  final double? subtotalAmount;
  final double? taxAmount;
}

class GroceryItemDraft {
  const GroceryItemDraft({
    required this.name,
    required this.amount,
    this.quantity,
    this.unitPrice,
  });

  final String name;
  final double amount;
  final double? quantity;
  final double? unitPrice;
}

class ExpenseRepository {
  ExpenseRepository(this._db);

  final Database _db;
  final _uuid = const Uuid();

  Future<List<Expense>> listActive() async {
    final rows = await _db.query(
      'expenses',
      where: 'deletedAt IS NULL',
      orderBy: 'date DESC, createdAt DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> listDeleted() async {
    final rows = await _db.query(
      'expenses',
      where: 'deletedAt IS NOT NULL',
      orderBy: 'deletedAt DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense?> getById(String id, {bool includeDeleted = false}) async {
    final rows = await _db.query(
      'expenses',
      where: includeDeleted ? 'id = ?' : 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  Future<Expense> create(ExpenseDraft draft) async {
    final now = DateTime.now().toIso8601String();
    final title =
        draft.title.trim().isEmpty ? 'Household expense' : draft.title.trim();
    final expense = Expense(
      id: _uuid.v4(),
      amount: draft.amount,
      currency: draft.currency,
      categoryId: draft.categoryId,
      title: title,
      vendor: _blankToNull(draft.vendor),
      date: DateTime(draft.date.year, draft.date.month, draft.date.day)
          .toIso8601String(),
      notes: _blankToNull(draft.notes),
      receiptImageUri: draft.receiptImageUri,
      isRecurring: false,
      createdAt: now,
      updatedAt: now,
      subtotalAmount: draft.subtotalAmount,
      taxAmount: draft.taxAmount,
    );

    await _db.transaction((txn) async {
      await txn.insert('expenses', expense.toMap());
      await _replaceGroceryItems(txn, expense.id, draft.groceryItems, now);
    });
    return expense;
  }

  Future<void> update(Expense expense,
      {List<GroceryItemDraft>? groceryItems}) async {
    await _db.transaction((txn) async {
      await txn.update(
        'expenses',
        expense.copyWith(updatedAt: DateTime.now().toIso8601String()).toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      if (groceryItems != null) {
        await _replaceGroceryItems(
            txn, expense.id, groceryItems, DateTime.now().toIso8601String());
      }
    });
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().toIso8601String();
    await _db.update(
      'expenses',
      {'deletedAt': now, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    await _db.update(
      'expenses',
      {'deletedAt': null, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentlyDelete(String id) async {
    await _db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GroceryItem>> groceryItemsForExpense(String expenseId) async {
    final rows = await _db.query(
      'grocery_items',
      where: 'expenseId = ?',
      whereArgs: [expenseId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(GroceryItem.fromMap).toList();
  }

  Future<List<GroceryItem>> listAllGroceryItems() async {
    final rows = await _db.query(
      'grocery_items',
      orderBy: 'expenseId ASC, createdAt ASC, id ASC',
    );
    return rows.map(GroceryItem.fromMap).toList();
  }

  Future<void> _replaceGroceryItems(
    DatabaseExecutor txn,
    String expenseId,
    List<GroceryItemDraft> items,
    String now,
  ) async {
    await txn.delete('grocery_items',
        where: 'expenseId = ?', whereArgs: [expenseId]);
    for (final item in items
        .where((item) => item.name.trim().isNotEmpty && item.amount > 0)) {
      await txn.insert(
        'grocery_items',
        GroceryItem(
          id: _uuid.v4(),
          expenseId: expenseId,
          name: item.name.trim(),
          amount: item.amount,
          createdAt: now,
        ).toMap(),
      );
    }
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
