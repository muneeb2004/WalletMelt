import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/expense_repository.dart';

void main() {
  test(
      'mirrors V1 expense CRUD, sorting, soft-delete, grocery, and receipt behavior',
      () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftExpenseRepository(db);

    final older = await repository.create(
      ExpenseDraft(
        amount: 5000,
        currency: 'PKR',
        categoryId: 'electricity',
        title: '',
        vendor: 'K-Electric',
        date: DateTime(2026, 5, 10),
        receiptImageUri: 'file:///receipts/electricity.jpg',
      ),
    );
    final grocery = await repository.create(
      ExpenseDraft(
        amount: 8450,
        currency: 'PKR',
        categoryId: 'grocery',
        title: 'Imtiaz grocery',
        vendor: ' Imtiaz ',
        date: DateTime(2026, 6, 14),
        notes: 'Monthly stock',
        receiptImageUri: 'file:///receipts/grocery.jpg',
        groceryItems: const [
          GroceryItemDraft(name: 'Milk', amount: 520),
          GroceryItemDraft(name: 'Eggs', amount: 420),
          GroceryItemDraft(name: '  ', amount: 300),
          GroceryItemDraft(name: 'Ignored', amount: 0),
        ],
      ),
    );

    expect(older.title, 'Household expense');
    expect(grocery.vendor, 'Imtiaz');

    final active = await repository.listActive();
    expect(active.map((expense) => expense.id), [grocery.id, older.id]);
    expect(
        active.fold<double>(0, (sum, expense) => sum + expense.amount), 13450);

    final loaded = await repository.getById(grocery.id);
    expect(loaded?.receiptImageUri, 'file:///receipts/grocery.jpg');
    expect(loaded?.categoryId, 'grocery');

    var groceryItems = await repository.groceryItemsForExpense(grocery.id);
    expect(groceryItems.map((item) => item.name), ['Milk', 'Eggs']);
    expect(groceryItems.map((item) => item.amount), [520, 420]);

    final expenseItems = await repository.expenseItemsForExpense(grocery.id);
    expect(expenseItems.map((item) => item.nameSnapshot), ['Milk', 'Eggs']);
    expect(
        expenseItems.every((item) =>
            item.quantity == null &&
            item.unitId == null &&
            item.unitPrice == null),
        isTrue);

    var receipts = await (db.select(db.receipts)
          ..where((receipt) => receipt.expenseId.equals(grocery.id)))
        .get();
    expect(receipts.single.uri, 'file:///receipts/grocery.jpg');

    await repository.update(
      grocery.copyWith(
        amount: 9000,
        notes: 'Updated stock',
        clearReceipt: true,
      ),
      groceryItems: const [
        GroceryItemDraft(name: 'Rice', amount: 2150),
      ],
    );
    final updated = await repository.getById(grocery.id);
    expect(updated?.amount, 9000);
    expect(updated?.notes, 'Updated stock');
    expect(updated?.receiptImageUri, isNull);
    groceryItems = await repository.groceryItemsForExpense(grocery.id);
    expect(groceryItems.map((item) => item.name), ['Rice']);
    receipts = await (db.select(db.receipts)
          ..where((receipt) => receipt.expenseId.equals(grocery.id)))
        .get();
    expect(receipts, isEmpty);

    await repository.softDelete(grocery.id);
    expect(await repository.getById(grocery.id), isNull);
    expect(
        await repository.getById(grocery.id, includeDeleted: true), isNotNull);
    expect((await repository.listActive()).map((expense) => expense.id),
        [older.id]);
    expect((await repository.listDeleted()).map((expense) => expense.id),
        [grocery.id]);

    await repository.restore(grocery.id);
    expect(await repository.getById(grocery.id), isNotNull);

    await repository.permanentlyDelete(grocery.id);
    expect(await repository.getById(grocery.id, includeDeleted: true), isNull);
    expect(await repository.groceryItemsForExpense(grocery.id), isEmpty);
    expect(await repository.expenseItemsForExpense(grocery.id), isEmpty);
  });
}
