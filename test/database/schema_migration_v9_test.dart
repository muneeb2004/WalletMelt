import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/schema/database_schema.dart';

void main() {
  test('V8 database migrates cleanly to V9, creating monthly_budgets table, index and migration_audit entry', () async {
    final tempDir = await Directory.systemTemp.createTemp('wallet_melt_v9_migration_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final dbPath = '${tempDir.path}${Platform.pathSeparator}test_v8_to_v9.db';

    // 1. Create V8 database fixture with user_version = 8
    final rawDb = sqlite3.sqlite3.open(dbPath);
    rawDb
      ..execute('PRAGMA foreign_keys = ON;')
      ..execute(DatabaseSchema.createCategories)
      ..execute(DatabaseSchema.createExpenses)
      ..execute(DatabaseSchema.createGroceryItems)
      ..execute(DatabaseSchema.createBudgets)
      ..execute(DatabaseSchema.createSyncMetadata)
      ..execute('''
        CREATE TABLE migration_audit (
          id TEXT NOT NULL PRIMARY KEY,
          fromVersion INTEGER NOT NULL,
          toVersion INTEGER NOT NULL,
          startedAt TEXT NOT NULL,
          completedAt TEXT,
          status TEXT NOT NULL,
          errorMessage TEXT,
          preMigrationBackupPath TEXT
        );
      ''')
      ..execute('PRAGMA user_version = 8;')
      ..close();

    // 2. Open with Drift WalletMeltDatabase which triggers onUpgrade to V9
    final driftDb = WalletMeltDatabase(
      NativeDatabase.createInBackground(File(dbPath)),
    );

    addTearDown(() async {
      await driftDb.close();
      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    // Verify user_version is now 9
    final versionResult = await driftDb.customSelect('PRAGMA user_version;').getSingle();
    final currentVersion = versionResult.read<int>('user_version');
    expect(currentVersion, 9);

    // Verify monthly_budgets table exists
    final tableCheck = await driftDb.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='monthly_budgets';",
    ).getSingleOrNull();
    expect(tableCheck, isNotNull);

    // Verify index monthly_budgets_month_idx exists
    final indexCheck = await driftDb.customSelect(
      "SELECT name FROM sqlite_master WHERE type='index' AND name='monthly_budgets_month_idx';",
    ).getSingleOrNull();
    expect(indexCheck, isNotNull);

    // Verify migration_audit has entry for 8 -> 9
    final auditCheck = await driftDb.customSelect(
      'SELECT * FROM migration_audit WHERE fromVersion = 8 AND toVersion = 9;',
    ).getSingleOrNull();
    expect(auditCheck, isNotNull);
    expect(auditCheck?.read<String>('status'), 'completed');

    // Test writing and reading from monthly_budgets table
    await driftDb.customStatement(
      'INSERT INTO monthly_budgets (id, month, amount, currency, createdAt, updatedAt) '
      "VALUES ('mb_1', '2026-06', 4500.0, 'USD', '2026-06-01T00:00:00Z', '2026-06-01T00:00:00Z');",
    );

    final row = await driftDb.customSelect(
      "SELECT * FROM monthly_budgets WHERE month = '2026-06';",
    ).getSingle();
    expect(row.read<String>('id'), 'mb_1');
    expect(row.read<double>('amount'), 4500.0);
    expect(row.read<String>('currency'), 'USD');
  });
}
