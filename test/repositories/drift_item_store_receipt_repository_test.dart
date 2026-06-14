import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_item_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_receipt_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_store_repository.dart';
import 'package:wallet_melt/src/data/repositories/expense_repository.dart';

void main() {
  test('item repository normalizes names, reuses canonical items, and resolves aliases', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftItemRepository(db);

    final milk = await repository.createOrGet(name: '  Milk  ', categoryId: 'grocery', defaultUnitId: 'litre');
    final sameMilk = await repository.createOrGet(name: 'milk');
    expect(sameMilk.id, milk.id);
    expect(milk.normalizedName, 'milk');

    await repository.addAlias(itemId: milk.id, alias: 'Doodh');
    final resolved = await repository.resolveAlias(' doodh ');
    expect(resolved?.id, milk.id);
  });

  test('store repository normalizes names and reuses canonical stores', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftStoreRepository(db);

    final store = await repository.createOrGet(name: '  Imtiaz Super Market  ');
    final sameStore = await repository.createOrGet(name: 'imtiaz   super market');

    expect(store.id, sameStore.id);
    expect(store.normalizedName, 'imtiaz super market');
  });

  test('receipt repository creates, lists, and soft deletes receipt records', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final expenseRepository = DriftExpenseRepository(db);
    final receiptRepository = DriftReceiptRepository(db);

    final expense = await expenseRepository.create(
      ExpenseDraft(
        amount: 1000,
        currency: 'PKR',
        categoryId: 'grocery',
        title: 'Receipt test',
        date: DateTime(2026, 6, 14),
      ),
    );

    final receipt = await receiptRepository.create(
      expenseId: expense.id,
      uri: 'file:///receipts/extra.jpg',
      mimeType: 'image/jpeg',
      fileSizeBytes: 1234,
    );

    var receipts = await receiptRepository.listForExpense(expense.id);
    expect(receipts.map((item) => item.uri), ['file:///receipts/extra.jpg']);
    expect(receipts.single.fileSizeBytes, 1234);

    await receiptRepository.softDelete(receipt.id);
    receipts = await receiptRepository.listForExpense(expense.id);
    expect(receipts, isEmpty);
    receipts = await receiptRepository.listForExpense(expense.id, includeDeleted: true);
    expect(receipts.single.deletedAt, isNotNull);
  });
}
