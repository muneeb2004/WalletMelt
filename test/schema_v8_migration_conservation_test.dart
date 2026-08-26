import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';


void main() {
  group('Schema v8 Migration & Strict Per-Row Conservation Tests', () {
    test('Migration v7 -> v8 populates amountMinorUnits and passes per-row equality check', () async {
      // 1. Set up an in-memory database at schema version 7
      final inMemoryExecutor = NativeDatabase.memory();
      final db = WalletMeltDatabase(inMemoryExecutor);

      // Create v7 schema manually or let onCreate set up tables
      await db.customStatement('PRAGMA foreign_keys = OFF;');

      // Create v7 tables with REAL amount columns
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS expenses (
          id TEXT PRIMARY KEY,
          amount REAL NOT NULL,
          currency TEXT NOT NULL,
          categoryId TEXT NOT NULL,
          title TEXT NOT NULL,
          vendor TEXT,
          storeId TEXT,
          date TEXT NOT NULL,
          notes TEXT,
          receiptImageUri TEXT,
          isRecurring INTEGER NOT NULL DEFAULT 0,
          recurrenceFrequency TEXT,
          itemizationStatus TEXT,
          itemTotalMismatchApproved INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          deletedAt TEXT,
          subtotalAmount REAL,
          taxAmount REAL
        );
      ''');

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS category_budgets (
          id TEXT PRIMARY KEY,
          categoryId TEXT NOT NULL,
          amount REAL NOT NULL,
          currency TEXT NOT NULL,
          month TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        );
      ''');

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS migration_audit (
          id TEXT PRIMARY KEY,
          fromVersion INTEGER NOT NULL,
          toVersion INTEGER NOT NULL,
          startedAt TEXT NOT NULL,
          completedAt TEXT,
          status TEXT NOT NULL,
          errorMessage TEXT,
          preMigrationBackupPath TEXT
        );
      ''');

      // Insert test rows with known real amounts
      await db.customStatement('''
        INSERT INTO expenses (id, amount, currency, categoryId, title, date, isRecurring, createdAt, updatedAt)
        VALUES ('exp_1', 10.50, 'USD', 'cat_1', 'Lunch', '2026-06-15', 0, '2026-06-15T12:00:00', '2026-06-15T12:00:00'),
               ('exp_2', 0.99, 'USD', 'cat_1', 'Coffee', '2026-06-15', 0, '2026-06-15T12:00:00', '2026-06-15T12:00:00'),
               ('exp_3', 100.00, 'USD', 'cat_1', 'Groceries', '2026-06-15', 0, '2026-06-15T12:00:00', '2026-06-15T12:00:00');
      ''');

      await db.customStatement('''
        INSERT INTO category_budgets (id, categoryId, amount, currency, month, createdAt, updatedAt)
        VALUES ('bgt_1', 'cat_1', 500.00, 'USD', '2026-06', '2026-06-01T00:00:00', '2026-06-01T00:00:00');
      ''');

      // 2. Execute migration from v7 to v8
      final migrator = db.createMigrator();
      await db.migration.onUpgrade(migrator, 7, 8);

      // 3. Verify that amountMinorUnits matches per-row CAST(ROUND(amount * 100) AS INTEGER)
      final expRows = await db.customSelect(
        'SELECT id, amount, amountMinorUnits FROM expenses ORDER BY id;'
      ).get();

      expect(expRows.length, 3);
      expect(expRows[0].read<int>('amountMinorUnits'), 1050);
      expect(expRows[1].read<int>('amountMinorUnits'), 99);
      expect(expRows[2].read<int>('amountMinorUnits'), 10000);

      final bgtRows = await db.customSelect(
        'SELECT id, amount, amountMinorUnits FROM category_budgets;'
      ).get();
      expect(bgtRows.length, 1);
      expect(bgtRows[0].read<int>('amountMinorUnits'), 50000);

      // 4. Verify zero mismatches in the entire database
      final mismatch = await db.customSelect(
        'SELECT count(*) as count FROM expenses WHERE amountMinorUnits != CAST(ROUND(amount * 100) AS INTEGER);'
      ).getSingle();
      expect(mismatch.read<int>('count'), 0);

      // 5. Verify audit log entry marked as success
      final audit = await db.customSelect(
        'SELECT status, fromVersion, toVersion FROM migration_audit ORDER BY startedAt DESC;'
      ).getSingle();
      expect(audit.read<String>('status'), 'success');
      expect(audit.read<int>('fromVersion'), 7);
      expect(audit.read<int>('toVersion'), 8);

      await db.close();
    });
  });
}
