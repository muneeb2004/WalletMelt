import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;

void main() {
  test('V11 database gains nullable accountId on debts and subscriptions',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('wallet_melt_v12_migration_');
    final dbPath = '${tempDir.path}${Platform.pathSeparator}v11_to_v12.db';

    final raw = sqlite3.sqlite3.open(dbPath);
    raw
      ..execute('PRAGMA foreign_keys = ON;')
      ..execute('''
        CREATE TABLE migration_audit (
          id TEXT NOT NULL PRIMARY KEY, fromVersion INTEGER NOT NULL,
          toVersion INTEGER NOT NULL, startedAt TEXT NOT NULL, completedAt TEXT,
          status TEXT NOT NULL, errorMessage TEXT, preMigrationBackupPath TEXT);
      ''')
      ..execute('''
        CREATE TABLE debt_records (
          id TEXT NOT NULL PRIMARY KEY, personName TEXT NOT NULL, payeeId TEXT,
          type TEXT NOT NULL, principalAmount REAL NOT NULL,
          remainingAmount REAL NOT NULL, principalAmountMinorUnits INTEGER,
          remainingAmountMinorUnits INTEGER, currency TEXT NOT NULL,
          description TEXT, createdAt TEXT NOT NULL, dueDate TEXT, settledAt TEXT,
          status TEXT NOT NULL, notes TEXT);
      ''')
      ..execute('''
        CREATE TABLE subscriptions (
          id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
          categoryId TEXT NOT NULL, amount REAL NOT NULL, taxAmount REAL,
          amountMinorUnits INTEGER, taxAmountMinorUnits INTEGER,
          currency TEXT NOT NULL, description TEXT, startDate TEXT NOT NULL,
          nextOccurrenceDate TEXT NOT NULL, billingCycle TEXT NOT NULL,
          status TEXT NOT NULL, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
          cancelledAt TEXT, notificationOffset INTEGER, deletedAt TEXT,
          version INTEGER NOT NULL DEFAULT 1);
      ''')
      ..execute("INSERT INTO debt_records (id, personName, type, principalAmount, remainingAmount, currency, createdAt, status) VALUES ('d1','Ali','loanGiven',500,500,'PKR','2026-06-01','active');")
      ..execute('PRAGMA user_version = 11;')
      ..close();

    final db = WalletMeltDatabase(NativeDatabase(File(dbPath)));
    addTearDown(() async {
      await db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    for (final table in ['debt_records', 'subscriptions']) {
      final cols = await db.customSelect('PRAGMA table_info($table);').get();
      final col = cols.firstWhere((c) => c.read<String>('name') == 'accountId');
      expect(col.read<int>('notnull'), 0, reason: table);
    }
    final row = await db
        .customSelect("SELECT principalAmount, accountId FROM debt_records WHERE id = 'd1';")
        .getSingle();
    expect(row.read<double>('principalAmount'), 500);
    expect(row.data['accountId'], isNull);
    final audit = await db
        .customSelect(
            'SELECT status FROM migration_audit WHERE fromVersion = 11;')
        .getSingleOrNull();
    expect(audit?.read<String>('status'), 'completed');
    expect(
        (await db.customSelect('PRAGMA user_version;').getSingle())
            .read<int>('user_version'),
        WalletMeltDatabase.currentSchemaVersion);
  });
}
