import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../expense_repository.dart';
import '../../../types/expense.dart' as domain;
import '../../../types/grocery_item.dart' as domain;

class DriftExpenseRepository {
  DriftExpenseRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  Future<List<domain.Expense>> listActive() async {
    final rows = await (_db.select(_db.expenses)
          ..where((expense) => expense.deletedAt.isNull())
          ..orderBy([
            (expense) =>
                OrderingTerm(expression: expense.date, mode: OrderingMode.desc),
            (expense) => OrderingTerm(
                expression: expense.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<domain.Expense>> listDeleted() async {
    final rows = await (_db.select(_db.expenses)
          ..where((expense) => expense.deletedAt.isNotNull())
          ..orderBy([
            (expense) => OrderingTerm(
                expression: expense.deletedAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.Expense?> getById(String id,
      {bool includeDeleted = false}) async {
    final query = _db.select(_db.expenses)
      ..where((expense) => expense.id.equals(id));
    if (!includeDeleted) {
      query.where((expense) => expense.deletedAt.isNull());
    }
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  Future<domain.Expense> create(ExpenseDraft draft) async {
    final now = DateTime.now().toIso8601String();
    final title =
        draft.title.trim().isEmpty ? 'Household expense' : draft.title.trim();
    final expense = domain.Expense(
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
    );

    await _db.transaction(() async {
      await _db.into(_db.expenses).insert(_expenseInsertCompanion(expense));
      await _replaceGroceryItems(expense.id, draft.groceryItems, now,
          expense.currency, expense.categoryId);
      if (expense.receiptImageUri != null) {
        await _insertReceiptForLegacyPath(
            expense.id, expense.receiptImageUri!, now, null);
      }
    });
    return expense;
  }

  Future<void> update(domain.Expense expense,
      {List<GroceryItemDraft>? groceryItems}) async {
    final updatedAt = DateTime.now().toIso8601String();
    final updated = expense.copyWith(updatedAt: updatedAt);
    await _db.transaction(() async {
      await (_db.update(_db.expenses)
            ..where((row) => row.id.equals(expense.id)))
          .write(_expenseUpdateCompanion(updated));
      if (groceryItems != null) {
        await _replaceGroceryItems(expense.id, groceryItems, updatedAt,
            expense.currency, expense.categoryId);
      }
      await (_db.delete(_db.receipts)
            ..where((row) => row.id.equals(_legacyReceiptId(expense.id))))
          .go();
      if (updated.receiptImageUri != null) {
        await _insertReceiptForLegacyPath(
            updated.id, updated.receiptImageUri!, updatedAt, updated.deletedAt);
      }
    });
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.expenses)..where((expense) => expense.id.equals(id)))
        .write(
      local.ExpensesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> restore(String id) async {
    await (_db.update(_db.expenses)..where((expense) => expense.id.equals(id)))
        .write(
      local.ExpensesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> permanentlyDelete(String id) async {
    await (_db.delete(_db.expenses)..where((expense) => expense.id.equals(id)))
        .go();
  }

  Future<List<domain.GroceryItem>> groceryItemsForExpense(
      String expenseId) async {
    final rows = await (_db.select(_db.groceryItems)
          ..where((item) => item.expenseId.equals(expenseId))
          ..orderBy([
            (item) => OrderingTerm(expression: item.createdAt),
          ]))
        .get();
    return rows.map((row) {
      return domain.GroceryItem(
        id: row.id,
        expenseId: row.expenseId,
        name: row.name,
        amount: row.amount,
        createdAt: row.createdAt,
      );
    }).toList();
  }

  Future<List<domain.GroceryItem>> listAllGroceryItems() async {
    final rows = await (_db.select(_db.groceryItems)
          ..orderBy([
            (item) => OrderingTerm(expression: item.expenseId),
            (item) => OrderingTerm(expression: item.createdAt),
            (item) => OrderingTerm(expression: item.id),
          ]))
        .get();
    return rows.map((row) {
      return domain.GroceryItem(
        id: row.id,
        expenseId: row.expenseId,
        name: row.name,
        amount: row.amount,
        createdAt: row.createdAt,
      );
    }).toList();
  }

  Future<List<local.ExpenseItem>> expenseItemsForExpense(String expenseId) {
    return (_db.select(_db.expenseItems)
          ..where((item) => item.expenseId.equals(expenseId))
          ..orderBy([
            (item) => OrderingTerm(expression: item.createdAt),
          ]))
        .get();
  }

  Future<void> _replaceGroceryItems(
    String expenseId,
    List<GroceryItemDraft> items,
    String now,
    String currency,
    String categoryId,
  ) async {
    await (_db.delete(_db.groceryItems)
          ..where((item) => item.expenseId.equals(expenseId)))
        .go();
    await (_db.delete(_db.expenseItems)
          ..where((item) => item.expenseId.equals(expenseId)))
        .go();

    for (final item in items
        .where((item) => item.name.trim().isNotEmpty && item.amount > 0)) {
      final id = _uuid.v4();
      final name = item.name.trim();
      final normalizedName = _normalizeName(name);
      final canonicalItem = await _findOrCreateItem(
          name: name,
          normalizedName: normalizedName,
          categoryId: categoryId,
          now: now);

      await _db.into(_db.groceryItems).insert(
            local.GroceryItemsCompanion.insert(
              id: id,
              expenseId: expenseId,
              name: name,
              amount: item.amount,
              createdAt: now,
            ),
          );

      await _db.into(_db.expenseItems).insert(
            local.ExpenseItemsCompanion.insert(
              id: id,
              expenseId: expenseId,
              itemId: Value(canonicalItem.id),
              nameSnapshot: name,
              quantity: Value(item.quantity),
              unitPrice: Value(item.unitPrice),
              totalPrice: item.amount,
              currency: currency,
              categoryId: Value(categoryId),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  Future<local.Item> _findOrCreateItem({
    required String name,
    required String normalizedName,
    required String categoryId,
    required String now,
  }) async {
    final existing = await (_db.select(_db.items)
          ..where((item) => item.normalizedName.equals(normalizedName)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final itemId = _uuid.v4();
    await _db.into(_db.items).insert(
          local.ItemsCompanion.insert(
            id: itemId,
            name: name,
            normalizedName: normalizedName,
            categoryId: Value(categoryId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await (_db.select(_db.items)
          ..where((item) => item.id.equals(itemId)))
        .getSingle());
  }

  Future<void> _insertReceiptForLegacyPath(
      String expenseId, String uri, String createdAt, String? deletedAt) async {
    await _db.into(_db.receipts).insert(
          local.ReceiptsCompanion.insert(
            id: _legacyReceiptId(expenseId),
            expenseId: expenseId,
            uri: uri,
            mimeType: const Value('image/jpeg'),
            createdAt: createdAt,
            deletedAt: Value(deletedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  local.ExpensesCompanion _expenseInsertCompanion(domain.Expense expense) {
    return local.ExpensesCompanion.insert(
      id: expense.id,
      amount: expense.amount,
      currency: expense.currency,
      categoryId: expense.categoryId,
      title: expense.title,
      vendor: Value(expense.vendor),
      date: expense.date,
      notes: Value(expense.notes),
      receiptImageUri: Value(expense.receiptImageUri),
      isRecurring: Value(expense.isRecurring),
      recurrenceFrequency: Value(expense.recurrenceFrequency?.name),
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      deletedAt: Value(expense.deletedAt),
    );
  }

  local.ExpensesCompanion _expenseUpdateCompanion(domain.Expense expense) {
    return local.ExpensesCompanion(
      id: Value(expense.id),
      amount: Value(expense.amount),
      currency: Value(expense.currency),
      categoryId: Value(expense.categoryId),
      title: Value(expense.title),
      vendor: Value(expense.vendor),
      date: Value(expense.date),
      notes: Value(expense.notes),
      receiptImageUri: Value(expense.receiptImageUri),
      isRecurring: Value(expense.isRecurring),
      recurrenceFrequency: Value(expense.recurrenceFrequency?.name),
      createdAt: Value(expense.createdAt),
      updatedAt: Value(expense.updatedAt),
      deletedAt: Value(expense.deletedAt),
    );
  }

  domain.Expense _toDomain(local.Expense row) {
    return domain.Expense(
      id: row.id,
      amount: row.amount,
      currency: row.currency,
      categoryId: row.categoryId,
      title: row.title,
      vendor: row.vendor,
      date: row.date,
      notes: row.notes,
      receiptImageUri: row.receiptImageUri,
      isRecurring: row.isRecurring,
      recurrenceFrequency: _frequencyFromName(row.recurrenceFrequency),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  domain.RecurrenceFrequency? _frequencyFromName(String? name) {
    if (name == null) return null;
    for (final value in domain.RecurrenceFrequency.values) {
      if (value.name == name) return value;
    }
    return null;
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _legacyReceiptId(String expenseId) => 'legacy_receipt_$expenseId';
}
