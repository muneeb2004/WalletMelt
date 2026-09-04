import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_store_repository.dart';
import 'package:wallet_melt/src/data/schema/database_schema.dart';

void main() {
  test('V6 database with existing stores migrates to V7 preserving all store fields and adding new columns', () async {
    final tempDir = await Directory.systemTemp.createTemp('wallet_melt_v7_migration_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final dbPath = '${tempDir.path}${Platform.pathSeparator}test_v6_to_v7.db';
    
    // Create V6 database fixture in SQLite
    final rawDb = sqlite3.sqlite3.open(dbPath);
    rawDb
      ..execute('PRAGMA foreign_keys = ON;')
      ..execute(DatabaseSchema.createCategories)
      ..execute(DatabaseSchema.createExpenses)
      ..execute('ALTER TABLE expenses ADD COLUMN storeId TEXT REFERENCES stores(id);')
      ..execute(DatabaseSchema.createGroceryItems)
      ..execute(DatabaseSchema.createBudgets)
      ..execute(DatabaseSchema.createSyncMetadata)
      ..execute(
          "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('grocery', 'Grocery', 'shopping_basket', '#8FD6B5', 1, '2026-06-01T00:00:00.000', '2026-06-01T00:00:00.000');")
      ..execute(
          "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('fuel', 'Fuel', 'local_gas_station', '#F4B740', 1, '2026-06-01T00:00:00.000', '2026-06-01T00:00:00.000');")
      ..execute('''
        CREATE TABLE stores (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          normalizedName TEXT NOT NULL UNIQUE,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          archivedAt TEXT
        );

        CREATE TABLE units (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          abbreviation TEXT NOT NULL,
          dimension TEXT NOT NULL,
          baseUnitId TEXT,
          factorToBase REAL,
          isDefault INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        );

        CREATE TABLE items (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          normalizedName TEXT NOT NULL UNIQUE,
          defaultUnitId TEXT,
          categoryId TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        );

        CREATE TABLE item_aliases (
          id TEXT NOT NULL PRIMARY KEY,
          itemId TEXT NOT NULL,
          alias TEXT NOT NULL,
          normalizedAlias TEXT NOT NULL UNIQUE,
          createdAt TEXT NOT NULL
        );

        CREATE TABLE expense_items (
          id TEXT NOT NULL PRIMARY KEY,
          expenseId TEXT NOT NULL,
          itemId TEXT,
          rawItemName TEXT NOT NULL,
          quantity REAL NOT NULL,
          unitId TEXT,
          unitPrice REAL NOT NULL,
          totalPrice REAL NOT NULL,
          storeId TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        );

        CREATE TABLE receipts (
          id TEXT NOT NULL PRIMARY KEY,
          expenseId TEXT NOT NULL,
          imageUri TEXT NOT NULL,
          parsedText TEXT,
          mimeType TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          deletedAt TEXT
        );

        CREATE TABLE migration_audit (
          id TEXT NOT NULL PRIMARY KEY,
          fromVersion INTEGER NOT NULL,
          toVersion INTEGER NOT NULL,
          startedAt TEXT NOT NULL,
          completedAt TEXT,
          status TEXT NOT NULL,
          preMigrationBackupPath TEXT,
          detailsJson TEXT
        );

        CREATE TABLE subscriptions (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          currency TEXT NOT NULL,
          categoryId TEXT NOT NULL,
          billingPeriod TEXT NOT NULL,
          customIntervalDays INTEGER,
          firstBillingDate TEXT NOT NULL,
          nextOccurrenceDate TEXT NOT NULL,
          status TEXT NOT NULL,
          remindMe INTEGER NOT NULL,
          reminderDaysBefore INTEGER NOT NULL,
          paymentMethod TEXT,
          notes TEXT,
          cancellationUrl TEXT,
          pausedAt TEXT,
          canceledAt TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          archivedAt TEXT
        );

        CREATE TABLE payees (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          normalizedName TEXT NOT NULL UNIQUE,
          phone TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          deletedAt TEXT
        );

        CREATE TABLE debt_records (
          id TEXT NOT NULL PRIMARY KEY,
          payeeId TEXT,
          personName TEXT NOT NULL,
          type TEXT NOT NULL,
          principalAmount REAL NOT NULL,
          remainingAmount REAL NOT NULL,
          currency TEXT NOT NULL,
          description TEXT,
          createdAt TEXT NOT NULL,
          dueDate TEXT,
          settledAt TEXT,
          status TEXT NOT NULL,
          notes TEXT
        );

        CREATE TABLE essential_expense_templates (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          categoryId TEXT NOT NULL,
          mode TEXT NOT NULL,
          fixedAmount REAL,
          fixedUnit TEXT,
          unitRate REAL,
          expectedUsage REAL,
          notes TEXT,
          isActive INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          deletedAt TEXT
        );

        CREATE TABLE fuel_template_components (
          id TEXT NOT NULL PRIMARY KEY,
          templateId TEXT NOT NULL,
          fuelType TEXT NOT NULL,
          expectedLitres REAL NOT NULL,
          pricePerLitre REAL NOT NULL,
          createdAt TEXT NOT NULL
        );

        CREATE TABLE fuel_transactions (
          id TEXT NOT NULL PRIMARY KEY,
          expenseId TEXT NOT NULL,
          odometerReading REAL,
          createdAt TEXT NOT NULL
        );

        CREATE TABLE fuel_components (
          id TEXT NOT NULL PRIMARY KEY,
          fuelTransactionId TEXT NOT NULL,
          fuelType TEXT NOT NULL,
          quantityLitres REAL NOT NULL,
          pricePerLitre REAL NOT NULL,
          subtotal REAL NOT NULL,
          createdAt TEXT NOT NULL
        );

        PRAGMA user_version = 6;
      ''')
      ..execute('''
        INSERT INTO stores (id, name, normalizedName, notes, createdAt, updatedAt, archivedAt)
        VALUES 
          ('store_1', 'Subway Clifton', 'subway clifton', 'Pre-migration note', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000', NULL),
          ('store_2', 'Shell Fuel', 'shell fuel', NULL, '2026-01-02T00:00:00.000', '2026-01-02T00:00:00.000', NULL);

        INSERT INTO expenses (id, amount, currency, categoryId, title, vendor, storeId, date, isRecurring, createdAt, updatedAt)
        VALUES
          ('exp_1', 1500.0, 'PKR', 'grocery', 'Lunch', 'Subway Clifton', 'store_1', '2026-01-01T12:00:00.000', 0, '2026-01-01T12:00:00.000', '2026-01-01T12:00:00.000');
      ''');
    rawDb.close();

    // Open through Drift to trigger V6 -> V7 migration
    final db = WalletMeltDatabase(NativeDatabase.createInBackground(File(dbPath)));
    addTearDown(db.close);

    final storeRepo = DriftStoreRepository(db);
    final subway = await storeRepo.getByNormalizedName('subway clifton');
    expect(subway, isNotNull);
    expect(subway!.id, 'store_1');
    expect(subway.name, 'Subway Clifton');
    expect(subway.normalizedName, 'subway clifton');
    expect(subway.notes, 'Pre-migration note');
    expect(subway.createdAt, '2026-01-01T00:00:00.000');
    expect(subway.defaultCategoryId, isNull);
    expect(subway.isSaved, isFalse);
    expect(subway.isFavorite, isFalse);
    expect(subway.lastUsedAt, isNull);

    // Assert PRAGMA user_version is current schema version (9)
    expect(WalletMeltDatabase.currentSchemaVersion, 9);


    // Assert new operations work seamlessly on migrated database
    final promoted = await storeRepo.saveMerchant(
      name: 'Subway Clifton',
      defaultCategoryId: 'grocery',
      isFavorite: true,
    );
    expect(promoted.id, 'store_1');
    expect(promoted.isSaved, isTrue);
    expect(promoted.isFavorite, isTrue);
    expect(promoted.defaultCategoryId, 'grocery');
  });
}
