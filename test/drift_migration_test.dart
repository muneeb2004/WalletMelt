import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_receipt_repository.dart';
import 'package:wallet_melt/src/data/schema/database_schema.dart';

void main() {
  test('Drift database initializes and seeds default units', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final units = await db.select(db.units).get();
    final ids = units.map((unit) => unit.id).toSet();

    expect(
        ids,
        containsAll([
          'piece',
          'dozen',
          'kg',
          'g',
          'litre',
          'ml',
          'pack',
          'bag',
          'bottle',
          'bill'
        ]));
    expect(units, hasLength(10));
  });

  test('V1 fixture migrates to V2 while preserving core records and totals',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('wallet_melt_migration_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final dbFile = File(
        '${tempDir.path}${Platform.pathSeparator}${DatabaseSchema.databaseName}');
    _createV1Fixture(dbFile.path);

    final backupPath =
        await WalletMeltDatabase.createPreV2BackupIfNeeded(dbFile.path);
    expect(backupPath, isNotNull);
    expect(await File(backupPath!).exists(), isTrue);

    final db = WalletMeltDatabase(
      NativeDatabase.createInBackground(dbFile),
      preMigrationBackupPath: backupPath,
    );
    addTearDown(db.close);

    final metrics = await db.readV1MigrationMetrics();
    expect(metrics.expenseCount, 3);
    expect(metrics.categoryCount, 3);
    expect(metrics.budgetCount, 1);
    expect(metrics.groceryItemCount, 3);
    expect(metrics.activeExpenseTotal, 13450);
    expect(metrics.softDeletedExpenseCount, 1);
    expect(metrics.receiptPathCount, 2);

    final expenseItems = await db.select(db.expenseItems).get();
    expect(expenseItems, hasLength(3));

    final milk = expenseItems.singleWhere((item) => item.id == 'gi_milk');
    expect(milk.expenseId, 'exp_grocery_active');
    expect(milk.nameSnapshot, 'Milk');
    expect(milk.totalPrice, 520);
    expect(milk.quantity, isNull);
    expect(milk.unitId, isNull);
    expect(milk.unitPrice, isNull);
    expect(milk.createdAt, '2026-06-14T10:00:00.000');

    final canonicalItems = await db.select(db.items).get();
    expect(canonicalItems.map((item) => item.normalizedName),
        containsAll(['milk', 'eggs', 'legacy deleted item']));
    expect(milk.itemId, isNotNull);

    final receipts = await db.select(db.receipts).get();
    expect(receipts, hasLength(2));
    expect(
        receipts.map((receipt) => receipt.uri),
        containsAll([
          'file:///receipts/grocery.jpg',
          'file:///receipts/electricity.jpg'
        ]));

    final deletedRows = await (db.select(db.expenses)
          ..where((expense) => expense.deletedAt.isNotNull()))
        .get();
    expect(deletedRows, hasLength(1));
    expect(deletedRows.single.id, 'exp_grocery_deleted');

    final categoryRepository = DriftCategoryRepository(db);
    final expenseRepository = DriftExpenseRepository(db);
    final budgetRepository = DriftBudgetRepository(db);
    final receiptRepository = DriftReceiptRepository(db);

    expect(
        (await categoryRepository.listCategories())
            .map((category) => category.id),
        containsAll(['grocery', 'electricity', 'rent']));
    expect((await expenseRepository.listActive()).map((expense) => expense.id),
        ['exp_grocery_active', 'exp_electricity_active']);
    expect((await expenseRepository.listDeleted()).map((expense) => expense.id),
        ['exp_grocery_deleted']);
    expect(
        (await expenseRepository.groceryItemsForExpense('exp_grocery_active'))
            .map((item) => item.name),
        ['Milk', 'Eggs']);
    expect(
        (await expenseRepository.expenseItemsForExpense('exp_grocery_active'))
            .map((item) => item.nameSnapshot),
        ['Milk', 'Eggs']);
    expect((await budgetRepository.listForMonth('2026-06')).single.categoryId,
        'grocery');
    expect(
        (await receiptRepository.listForExpense('exp_grocery_active'))
            .single
            .uri,
        'file:///receipts/grocery.jpg');

    final audits = await db.select(db.migrationAudit).get();
    expect(audits, hasLength(1));
    expect(audits.single.status, 'completed');
    expect(audits.single.preMigrationBackupPath, backupPath);
  });

  test('V1 migration tolerates partially applied V2 schema artifacts',
      () async {
    final tempDir = await Directory.systemTemp
        .createTemp('wallet_melt_partial_migration_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final dbFile = File(
        '${tempDir.path}${Platform.pathSeparator}${DatabaseSchema.databaseName}');
    _createV1Fixture(dbFile.path);
    _addPartiallyAppliedV2Shape(dbFile.path);

    final db = WalletMeltDatabase(NativeDatabase.createInBackground(dbFile));
    addTearDown(db.close);

    final expenses = await db.select(db.expenses).get();
    expect(expenses, hasLength(3));
    expect(
        expenses.singleWhere((row) => row.id == 'exp_grocery_active').storeId,
        isNull);

    final stores = await db.select(db.stores).get();
    expect(stores, isEmpty);

    final expenseItems = await db.select(db.expenseItems).get();
    expect(expenseItems.map((item) => item.id),
        containsAll(['gi_milk', 'gi_eggs', 'gi_deleted']));

    final audits = await db.select(db.migrationAudit).get();
    expect(audits.single.status, 'completed');

    final raw = sqlite3.sqlite3.open(dbFile.path);
    try {
      expect(raw.select('PRAGMA user_version;').first['user_version'],
          WalletMeltDatabase.currentSchemaVersion);
    } finally {
      raw.close();
    }
  });

  test('V4 to V5 migration creates payees for existing debt records and reassigns payeeId', () async {
    final tempDir = await Directory.systemTemp.createTemp('wallet_melt_v4_to_v5_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final dbFile = File('${tempDir.path}${Platform.pathSeparator}${DatabaseSchema.databaseName}');
    
    _createV1Fixture(dbFile.path);
    final raw = sqlite3.sqlite3.open(dbFile.path);
    try {
      raw
        ..execute('CREATE TABLE debt_records (id TEXT NOT NULL PRIMARY KEY, personName TEXT NOT NULL, type TEXT NOT NULL, principalAmount REAL NOT NULL, remainingAmount REAL NOT NULL, currency TEXT NOT NULL, description TEXT, createdAt TEXT NOT NULL, dueDate TEXT, settledAt TEXT, status TEXT NOT NULL, notes TEXT);')
        ..execute("INSERT INTO debt_records (id, personName, type, principalAmount, remainingAmount, currency, createdAt, status) VALUES ('debt_1', 'Ali Ahmed', 'loanGiven', 5000, 5000, 'PKR', '2026-07-01T10:00:00.000', 'active');")
        ..execute("INSERT INTO debt_records (id, personName, type, principalAmount, remainingAmount, currency, createdAt, status) VALUES ('debt_2', ' ali ahmed ', 'loanGiven', 2000, 2000, 'PKR', '2026-07-02T10:00:00.000', 'active');")
        ..execute('PRAGMA user_version = 4;');
    } finally {
      raw.close();
    }

    final db = WalletMeltDatabase(NativeDatabase.createInBackground(dbFile));
    addTearDown(db.close);

    final payees = await db.select(db.payees).get();
    expect(payees, hasLength(1));
    expect(payees.first.name, 'Ali Ahmed');
    expect(payees.first.normalizedName, 'ali ahmed');

    final debtRecords = await db.select(db.debtRecords).get();
    expect(debtRecords, hasLength(2));
    expect(debtRecords[0].payeeId, payees.first.id);
    expect(debtRecords[1].payeeId, payees.first.id);
  });

  test('V5 to V6 migration creates essential templates and fuel tables', () async {
    final tempDir = await Directory.systemTemp.createTemp('wallet_melt_v5_to_v6_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final dbFile = File('${tempDir.path}${Platform.pathSeparator}${DatabaseSchema.databaseName}');
    _createV1Fixture(dbFile.path);

    final db = WalletMeltDatabase(NativeDatabase.createInBackground(dbFile));
    addTearDown(db.close);

    final essentials = await db.select(db.essentialExpenseTemplates).get();
    expect(essentials, isEmpty);

    final fuelTxs = await db.select(db.fuelTransactions).get();
    expect(fuelTxs, isEmpty);

    final raw = sqlite3.sqlite3.open(dbFile.path);
    try {
      expect(raw.select('PRAGMA user_version;').first['user_version'],
          WalletMeltDatabase.currentSchemaVersion);
    } finally {
      raw.close();
    }
  });
}

void _createV1Fixture(String path) {
  final db = sqlite3.sqlite3.open(path);
  try {
    db
      ..execute('PRAGMA foreign_keys = ON;')
      ..execute(DatabaseSchema.createCategories)
      ..execute(DatabaseSchema.createExpenses)
      ..execute(DatabaseSchema.createGroceryItems)
      ..execute(DatabaseSchema.createBudgets)
      ..execute(DatabaseSchema.createSyncMetadata)
      ..execute(
          "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('grocery', 'Grocery', 'shopping_basket', '#8FD6B5', 1, '2026-06-01T00:00:00.000', '2026-06-01T00:00:00.000');")
      ..execute(
          "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('electricity', 'Electricity', 'bolt', '#F4B740', 1, '2026-06-01T00:00:00.000', '2026-06-01T00:00:00.000');")
      ..execute(
          "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('rent', 'Rent', 'home', '#A88CC2', 1, '2026-06-01T00:00:00.000', '2026-06-01T00:00:00.000');")
      ..execute(
          "INSERT INTO expenses (id, amount, currency, categoryId, title, vendor, date, notes, receiptImageUri, isRecurring, recurrenceFrequency, createdAt, updatedAt, deletedAt) VALUES ('exp_grocery_active', 8450, 'PKR', 'grocery', 'Imtiaz grocery', 'Imtiaz', '2026-06-14T00:00:00.000', 'Monthly stock', 'file:///receipts/grocery.jpg', 0, NULL, '2026-06-14T10:00:00.000', '2026-06-14T10:00:00.000', NULL);")
      ..execute(
          "INSERT INTO expenses (id, amount, currency, categoryId, title, vendor, date, notes, receiptImageUri, isRecurring, recurrenceFrequency, createdAt, updatedAt, deletedAt) VALUES ('exp_electricity_active', 5000, 'PKR', 'electricity', 'Electricity bill', 'K-Electric', '2026-06-10T00:00:00.000', NULL, 'file:///receipts/electricity.jpg', 0, NULL, '2026-06-10T09:00:00.000', '2026-06-10T09:00:00.000', NULL);")
      ..execute(
          "INSERT INTO expenses (id, amount, currency, categoryId, title, vendor, date, notes, receiptImageUri, isRecurring, recurrenceFrequency, createdAt, updatedAt, deletedAt) VALUES ('exp_grocery_deleted', 1000, 'PKR', 'grocery', 'Deleted grocery', 'Old Store', '2026-05-11T00:00:00.000', NULL, NULL, 0, NULL, '2026-05-11T10:00:00.000', '2026-05-12T10:00:00.000', '2026-05-12T10:00:00.000');")
      ..execute(
          "INSERT INTO grocery_items (id, expenseId, name, amount, createdAt) VALUES ('gi_milk', 'exp_grocery_active', 'Milk', 520, '2026-06-14T10:00:00.000');")
      ..execute(
          "INSERT INTO grocery_items (id, expenseId, name, amount, createdAt) VALUES ('gi_eggs', 'exp_grocery_active', 'Eggs', 420, '2026-06-14T10:00:00.000');")
      ..execute(
          "INSERT INTO grocery_items (id, expenseId, name, amount, createdAt) VALUES ('gi_deleted', 'exp_grocery_deleted', 'Legacy Deleted Item', 1000, '2026-05-11T10:00:00.000');")
      ..execute(
          "INSERT INTO category_budgets (id, categoryId, amount, currency, month, createdAt, updatedAt) VALUES ('budget_grocery_june', 'grocery', 30000, 'PKR', '2026-06', '2026-06-01T00:00:00.000', '2026-06-01T00:00:00.000');")
      ..execute(
          "INSERT INTO sync_metadata (entityType, entityId, localVersion, remoteId, lastSyncedAt, syncState) VALUES ('expense', 'exp_grocery_active', 1, NULL, NULL, 'local_only');")
      ..execute('PRAGMA user_version = 1;');
  } finally {
    db.close();
  }
}

void _addPartiallyAppliedV2Shape(String path) {
  final db = sqlite3.sqlite3.open(path);
  try {
    db
      ..execute('''
CREATE TABLE stores (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  normalizedName TEXT NOT NULL UNIQUE,
  notes TEXT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  archivedAt TEXT NULL
);
''')
      ..execute(
          'ALTER TABLE expenses ADD COLUMN "storeId" TEXT NULL REFERENCES stores (id);')
      ..execute(
          'ALTER TABLE expenses ADD COLUMN "itemizationStatus" TEXT NULL;')
      ..execute(
          'ALTER TABLE expenses ADD COLUMN "itemTotalMismatchApproved" INTEGER NOT NULL DEFAULT 0 CHECK ("itemTotalMismatchApproved" IN (0, 1));')
      ..execute('PRAGMA user_version = 1;');
  } finally {
    db.close();
  }
}
