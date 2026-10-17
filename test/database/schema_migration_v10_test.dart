import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/schema/database_schema.dart';

void main() {
  test(
      'V9 database migrates to V10: accounts tables, nullable accountId, indexes, audit row, data untouched',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('wallet_melt_v10_migration_');
    final dbPath = '${tempDir.path}${Platform.pathSeparator}v9_to_v10.db';

    final rawDb = sqlite3.sqlite3.open(dbPath);
    rawDb
      ..execute('PRAGMA foreign_keys = ON;')
      ..execute(DatabaseSchema.createCategories)
      ..execute(DatabaseSchema.createExpenses)
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
      ..execute(
          "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('grocery','Grocery','i','c',1,'t','t');")
      ..execute(
          'INSERT INTO expenses (id, amount, currency, categoryId, title, date, isRecurring, createdAt, updatedAt) '
          "VALUES ('e1', 12.5, 'PKR', 'grocery', 'Milk', '2026-06-01T00:00:00.000', 0, 't', 't');")
      ..execute('PRAGMA user_version = 9;')
      ..close();

    final db = WalletMeltDatabase(NativeDatabase(File(dbPath)));
    addTearDown(() async {
      await db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    Future<bool> exists(String type, String name) async =>
        (await db
                .customSelect(
                    'SELECT name FROM sqlite_master WHERE type = ? AND name = ?;',
                    variables: [
                  Variable.withString(type),
                  Variable.withString(name)
                ])
                .getSingleOrNull()) !=
        null;

    expect(
        (await db.customSelect('PRAGMA user_version;').getSingle())
            .read<int>('user_version'),
        WalletMeltDatabase.currentSchemaVersion);
    expect(await exists('table', 'accounts'), isTrue);
    expect(await exists('table', 'account_movements'), isTrue);
    expect(await exists('index', 'expenses_accountId_date_idx'), isTrue);
    expect(
        await exists('index', 'account_movements_accountId_date_idx'), isTrue);

    final columns = await db.customSelect('PRAGMA table_info(expenses);').get();
    final accountCol =
        columns.firstWhere((c) => c.read<String>('name') == 'accountId');
    expect(accountCol.read<int>('notnull'), 0);

    final row = await db
        .customSelect("SELECT amount, accountId FROM expenses WHERE id = 'e1';")
        .getSingle();
    expect(row.read<double>('amount'), 12.5);
    expect(row.data['accountId'], isNull);

    final audit = await db
        .customSelect(
            'SELECT status FROM migration_audit WHERE fromVersion = 9 AND toVersion = ${WalletMeltDatabase.currentSchemaVersion};')
        .getSingleOrNull();
    expect(audit?.read<String>('status'), 'completed');
  });
}
