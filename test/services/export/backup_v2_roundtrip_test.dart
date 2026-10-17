import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' as local;
import 'package:wallet_melt/src/services/export/export_file_writer.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_conflict_service.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_encoder.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_extended_tables.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_validator.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_dry_run_planner.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_plan.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_restore_service.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart' as domain;
import 'package:wallet_melt/src/types/expense.dart' as domain;
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/monthly_budget.dart';
import 'package:wallet_melt/src/types/settings.dart';

const _ts = '2026-06-01T00:00:00.000';

/// Every table that a full backup must round-trip.
const _tables = [
  'categories',
  'expenses',
  'grocery_items',
  'category_budgets',
  'monthly_budgets',
  'units',
  'payees',
  'stores',
  'items',
  'item_aliases',
  'debt_records',
  'debt_repayments',
  'grocery_templates',
  'subscriptions',
  'essential_expense_templates',
  'fuel_template_components',
  'expense_items',
  'receipts',
  'fuel_transactions',
  'fuel_components',
  'accounts',
  'account_movements',
];

Future<void> _seed(local.WalletMeltDatabase db) async {
  Future<void> sql(String statement, [List<Object?> args = const []]) =>
      db.customStatement(statement, args);

  await sql(
      "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('c1','Tuition','school','#111111',0,'$_ts','$_ts');");
  await sql(
      "INSERT INTO units (id, name, abbreviation, dimension, isDefault, createdAt, updatedAt) VALUES ('u_base','Gram','g','mass',0,'$_ts','$_ts');");
  await sql(
      "INSERT INTO units (id, name, abbreviation, dimension, baseUnitId, factorToBase, isDefault, createdAt, updatedAt) VALUES ('u_kg','Kilo','kg','mass','u_base',1000,0,'$_ts','$_ts');");
  await sql(
      "INSERT INTO payees (id, name, normalizedName, createdAt, updatedAt) VALUES ('p1','Ali','ali','$_ts','$_ts');");
  await sql(
      "INSERT INTO stores (id, name, normalizedName, defaultCategoryId, createdAt, updatedAt) VALUES ('s1','Metro','metro','c1','$_ts','$_ts');");
  await sql(
      "INSERT INTO items (id, name, normalizedName, defaultUnitId, categoryId, createdAt, updatedAt) VALUES ('i1','Rice','rice','u_kg','c1','$_ts','$_ts');");
  await sql(
      "INSERT INTO item_aliases (id, itemId, alias, normalizedAlias, createdAt) VALUES ('ia1','i1','Chawal','chawal','$_ts');");
  await sql(
      "INSERT INTO accounts (id, name, type, currency, openingBalanceMinorUnits, openingDate, createdAt, updatedAt) VALUES ('a1','Bank','bank','PKR',500000,'2026-06-01T00:00:00.000','$_ts','$_ts');");
  await sql(
      "INSERT INTO accounts (id, name, type, currency, openingBalanceMinorUnits, openingDate, createdAt, updatedAt) VALUES ('a2','Wallet','wallet','PKR',0,'2026-06-01T00:00:00.000','$_ts','$_ts');");
  await sql(
      "INSERT INTO account_movements (id, accountId, kind, amountMinorUnits, date, transferGroupId, createdAt, updatedAt) VALUES ('m1','a1','transfer_out',-100000,'2026-06-04T00:00:00.000','tg1','$_ts','$_ts');");
  await sql(
      "INSERT INTO account_movements (id, accountId, kind, amountMinorUnits, date, transferGroupId, createdAt, updatedAt) VALUES ('m2','a2','transfer_in',100000,'2026-06-04T00:00:00.000','tg1','$_ts','$_ts');");
  await sql(
      "INSERT INTO expenses (id, amount, currency, categoryId, title, storeId, accountId, date, isRecurring, itemTotalMismatchApproved, createdAt, updatedAt) VALUES ('e1',1200,'PKR','c1','Groceries','s1','a1','2026-06-02T00:00:00.000',0,0,'$_ts','$_ts');");
  await sql(
      "INSERT INTO expenses (id, amount, currency, categoryId, title, date, isRecurring, itemTotalMismatchApproved, createdAt, updatedAt) VALUES ('e2',3000,'PKR','c1','Petrol','2026-06-03T00:00:00.000',0,0,'$_ts','$_ts');");
  await sql(
      "INSERT INTO grocery_items (id, expenseId, name, amount, createdAt) VALUES ('g1','e1','Milk',520,'$_ts');");
  // The expense-item row the app derives for grocery item g1 (same id).
  await sql(
      "INSERT INTO expense_items (id, expenseId, nameSnapshot, totalPrice, currency, categoryId, createdAt, updatedAt) VALUES ('g1','e1','Milk',520,'PKR','c1','$_ts','$_ts');");
  await sql(
      "INSERT INTO expense_items (id, expenseId, itemId, nameSnapshot, quantity, unitId, unitPrice, totalPrice, currency, storeId, categoryId, createdAt, updatedAt) VALUES ('ei1','e1','i1','Rice',2,'u_kg',340,680,'PKR','s1','c1','$_ts','$_ts');");
  await sql(
      "INSERT INTO receipts (id, expenseId, uri, createdAt) VALUES ('r1','e1','file:///r1.jpg','$_ts');");
  await sql(
      "INSERT INTO category_budgets (id, categoryId, amount, currency, month, createdAt, updatedAt) VALUES ('b1','c1',9000,'PKR','2026-06','$_ts','$_ts');");
  await sql(
      "INSERT INTO monthly_budgets (id, month, amount, currency, createdAt, updatedAt) VALUES ('mb1','2026-06',40000,'PKR','$_ts','$_ts');");
  await sql(
      "INSERT INTO debt_records (id, personName, payeeId, type, principalAmount, remainingAmount, currency, createdAt, status) VALUES ('d1','Ali','p1','owedToMe',500,300,'PKR','$_ts','partiallyPaid');");
  await sql(
      "INSERT INTO debt_repayments (id, debtId, amount, createdAt) VALUES ('dr1','d1',200,'$_ts');");
  await sql(
      "INSERT INTO grocery_templates (id, name, items, createdAt) VALUES ('gt1','Weekly','milk,eggs','$_ts');");
  await sql(
      "INSERT INTO subscriptions (id, name, categoryId, amount, currency, startDate, nextOccurrenceDate, billingCycle, status, createdAt, updatedAt) VALUES ('sub1','Netflix','c1',10,'PKR','2026-01-31','2026-07-31','monthly','active','$_ts','$_ts');");
  await sql(
      "INSERT INTO essential_expense_templates (id, name, categoryId, frequency, expectedAmount, isActive, isFuel, createdAt, updatedAt) VALUES ('et1','Fuel','c1','monthly',9000,1,1,'$_ts','$_ts');");
  await sql(
      "INSERT INTO fuel_template_components (id, templateId, fuelType, expectedLitres, expectedPricePerLitre, createdAt) VALUES ('ftc1','et1','regular',20,300,'$_ts');");
  await sql(
      "INSERT INTO fuel_transactions (id, expenseId, odometerReading, createdAt) VALUES ('ft1','e2',12000,'$_ts');");
  await sql(
      "INSERT INTO fuel_components (id, fuelTransactionId, fuelType, quantityLitres, pricePerLitre, subtotal, createdAt) VALUES ('fc1','ft1','regular',10,300,3000,'$_ts');");
}

Future<Map<String, int>> _counts(local.WalletMeltDatabase db) async {
  final result = <String, int>{};
  for (final table in _tables) {
    final row = await db.customSelect('SELECT COUNT(*) AS c FROM $table;').getSingle();
    result[table] = row.read<int>('c');
  }
  return result;
}

/// [legacyExtended] drops the schema-v10 keys to mimic a pre-accounts v2 file.
Future<String> _exportV2(local.WalletMeltDatabase db,
    {bool legacyExtended = false}) async {
  final extended = await BackupExtendedTables.export(db);
  if (legacyExtended) {
    final tables = Map<String, Object?>.from(extended['tables']! as Map);
    tables
      ..remove('accounts')
      ..remove('account_movements');
    extended
      ..['tables'] = tables
      ..remove('expense_account_links');
  }
  final categories = await db.select(db.categories).get();
  final expenses = await db.select(db.expenses).get();
  final grocery = await db.select(db.groceryItems).get();
  final budgets = await db.select(db.categoryBudgets).get();
  final monthly = await db.select(db.monthlyBudgets).get();
  return const WalletMeltJsonBackupEncoder().encode(
    expenses: [
      for (final e in expenses)
        domain.Expense(
          id: e.id,
          amount: e.amount,
          currency: e.currency,
          categoryId: e.categoryId,
          title: e.title,
          date: e.date,
          isRecurring: e.isRecurring,
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
          storeId: e.storeId,
        ),
    ],
    groceryItems: [
      for (final g in grocery)
        GroceryItem(
          id: g.id,
          expenseId: g.expenseId,
          name: g.name,
          amount: g.amount,
          createdAt: g.createdAt,
        ),
    ],
    categories: [
      for (final c in categories)
        domain.Category(
          id: c.id,
          name: c.name,
          icon: c.icon,
          color: c.color,
          isDefault: c.isDefault,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
        ),
    ],
    budgets: [
      for (final b in budgets)
        CategoryBudget(
          id: b.id,
          categoryId: b.categoryId,
          amount: b.amount,
          currency: b.currency,
          month: b.month,
          createdAt: b.createdAt,
          updatedAt: b.updatedAt,
        ),
    ],
    monthlyBudgets: [
      for (final m in monthly)
        MonthlyBudget(
          id: m.id,
          month: m.month,
          amount: m.amount,
          currency: m.currency,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
        ),
    ],
    settings: WalletMeltSettings.defaults,
    exportedAt: DateTime(2026, 6, 14),
    appVersion: '1.1.2+6',
    extended: extended,
    schemaVersion: local.WalletMeltDatabase.currentSchemaVersion,
  );
}

class _Settings extends SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}

Future<WalletMeltJsonRestoreResult> _restore(
  local.WalletMeltDatabase db,
  Directory tmp,
  String json,
  RestoreMode mode,
) async {
  final safety = File('${tmp.path}/safety.json')..writeAsStringSync('{"s":1}');
  final plan = const WalletMeltJsonRestoreDryRunPlanner().plan(
    jsonText: json,
    localSnapshot: LocalAppSnapshot(
      expenses: [
        for (final e in await db.select(db.expenses).get())
          domain.Expense(
            id: e.id,
            amount: e.amount,
            currency: e.currency,
            categoryId: e.categoryId,
            title: e.title,
            date: e.date,
            isRecurring: e.isRecurring,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
          ),
      ],
      deletedExpenses: const [],
      categories: [
        for (final c in await db.select(db.categories).get())
          domain.Category(
            id: c.id,
            name: c.name,
            icon: c.icon,
            color: c.color,
            isDefault: c.isDefault,
            createdAt: c.createdAt,
            updatedAt: c.updatedAt,
          ),
      ],
      budgets: const [],
      groceryItems: const [],
      settings: WalletMeltSettings.defaults,
    ),
    conflictSummary: const BackupConflictSummary(),
    settingsImportSelected: false,
    mode: mode,
  );
  final service =
      WalletMeltJsonRestoreService(database: db, settingsService: _Settings());
  final safetyResult = ExportFileResult(
    path: safety.path,
    fileName: 'safety.json',
    mimeType: ExportFileWriter.jsonMimeType,
    byteCount: 7,
    createdAt: DateTime(2026),
  );
  final options = WalletMeltJsonRestoreOptions(mode: mode, confirmed: true);
  return mode == RestoreMode.fullReplace
      ? service.restoreFullReplace(
          jsonText: json, dryRunPlan: plan, options: options, safetyBackup: safetyResult)
      : service.restoreSafeMerge(
          jsonText: json, dryRunPlan: plan, options: options, safetyBackup: safetyResult);
}

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('wm_v2_'));
  tearDown(() async => tmp.delete(recursive: true));

  test('v2 export is valid, checksummed, and tamper-evident', () async {
    final src = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(src.close);
    await _seed(src);
    final json = await _exportV2(src);

    expect(json, contains('"format_version": 2'));
    expect(json, contains('"checksum": "sha256:'));
    expect(const WalletMeltJsonBackupValidator().validate(json).isValid, isTrue);

    final tampered = json.replaceFirst('Netflix', 'Netfliy');
    final result = const WalletMeltJsonBackupValidator().validate(tampered);
    expect(result.isValid, isFalse);
    expect(result.error, contains('checksum'));
  });

  test('legacy v1 backups (no extended section) still validate', () {
    final json = const WalletMeltJsonBackupEncoder().encode(
      expenses: const [],
      groceryItems: const [],
      categories: const [],
      budgets: const [],
      settings: WalletMeltSettings.defaults,
      exportedAt: DateTime(2026, 6, 14),
    );
    expect(json, contains('"format_version": 1'));
    expect(const WalletMeltJsonBackupValidator().validate(json).isValid, isTrue);
  });

  test('full replace into an empty DB reproduces every table', () async {
    final src = local.WalletMeltDatabase(NativeDatabase.memory());
    final dst = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(src.close);
    addTearDown(dst.close);
    await _seed(src);
    final json = await _exportV2(src);

    final result = await _restore(dst, tmp, json, RestoreMode.fullReplace);
    expect(result.success, isTrue, reason: result.errorMessage);
    expect(await _counts(dst), await _counts(src));
    expect(await dst.customSelect('PRAGMA foreign_key_check;').get(), isEmpty);

    final store = await dst.customSelect("SELECT storeId FROM expenses WHERE id='e1'").getSingle();
    expect(store.read<String?>('storeId'), 's1');
    final minor = await dst.customSelect("SELECT remainingAmountMinorUnits AS m FROM debt_records WHERE id='d1'").getSingle();
    expect(minor.read<int?>('m'), 30000);
  });

  test('full replace into a populated DB replaces, never fails on foreign keys',
      () async {
    final src = local.WalletMeltDatabase(NativeDatabase.memory());
    final dst = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(src.close);
    addTearDown(dst.close);
    await _seed(src);
    final json = await _exportV2(src);

    // Destination holds different data that references its own categories.
    await dst.customStatement(
        "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('c_other','Other2','i','#000',0,'$_ts','$_ts');");
    await dst.customStatement(
        "INSERT INTO subscriptions (id, name, categoryId, amount, currency, startDate, nextOccurrenceDate, billingCycle, status, createdAt, updatedAt) VALUES ('sub_x','Spotify','c_other',5,'PKR','2026-01-01','2026-07-01','monthly','active','$_ts','$_ts');");
    await dst.customStatement(
        "INSERT INTO expenses (id, amount, currency, categoryId, title, date, isRecurring, itemTotalMismatchApproved, createdAt, updatedAt) VALUES ('e_x',9,'PKR','c_other','Old','2026-06-01',0,0,'$_ts','$_ts');");
    await dst.customStatement(
        "INSERT INTO fuel_transactions (id, expenseId, createdAt) VALUES ('ft_x','e_x','$_ts');");

    final result = await _restore(dst, tmp, json, RestoreMode.fullReplace);
    expect(result.success, isTrue, reason: result.errorMessage);
    expect(await _counts(dst), await _counts(src));
    expect(await dst.customSelect('PRAGMA foreign_key_check;').get(), isEmpty);
    final old = await dst.customSelect("SELECT COUNT(*) c FROM subscriptions WHERE id='sub_x'").getSingle();
    expect(old.read<int>('c'), 0);
  });

  test('full replace refuses a legacy v1 backup', () async {
    final dst = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(dst.close);
    final json = const WalletMeltJsonBackupEncoder().encode(
      expenses: const [],
      groceryItems: const [],
      categories: const [],
      budgets: const [],
      settings: WalletMeltSettings.defaults,
      exportedAt: DateTime(2026, 6, 14),
    );
    final result = await _restore(dst, tmp, json, RestoreMode.fullReplace);
    expect(result.success, isFalse);
    expect(result.errorMessage, contains('format v2'));
  });

  test('safe merge restores every domain without duplicating derived rows',
      () async {
    final src = local.WalletMeltDatabase(NativeDatabase.memory());
    final dst = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(src.close);
    addTearDown(dst.close);
    await _seed(src);
    final json = await _exportV2(src);

    final result = await _restore(dst, tmp, json, RestoreMode.safeMerge);
    expect(result.success, isTrue, reason: result.errorMessage);
    expect(await _counts(dst), await _counts(src));
    expect(await dst.customSelect('PRAGMA foreign_key_check;').get(), isEmpty);
  });

  test('safe merge keeps local rows and never touches pre-existing expenses',
      () async {
    final src = local.WalletMeltDatabase(NativeDatabase.memory());
    final dst = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(src.close);
    addTearDown(dst.close);
    await _seed(src);
    final json = await _exportV2(src);

    // Local data: same payee (natural-key collision), different debt.
    await dst.customStatement(
        "INSERT INTO payees (id, name, normalizedName, createdAt, updatedAt) VALUES ('p_local','Ali','ali','$_ts','$_ts');");
    final result = await _restore(dst, tmp, json, RestoreMode.safeMerge);
    expect(result.success, isTrue, reason: result.errorMessage);

    final payees = await dst.customSelect('SELECT COUNT(*) c FROM payees').getSingle();
    expect(payees.read<int>('c'), 1, reason: 'payee deduplicated by normalizedName');
    final debt = await dst.customSelect("SELECT payeeId FROM debt_records WHERE id='d1'").getSingle();
    expect(debt.read<String>('payeeId'), 'p_local', reason: 'FK remapped to existing payee');
    expect(await dst.customSelect('PRAGMA foreign_key_check;').get(), isEmpty);
  });

  test('accounts, movements and expense-account links round-trip', () async {
    final src = local.WalletMeltDatabase(NativeDatabase.memory());
    final replaceDst = local.WalletMeltDatabase(NativeDatabase.memory());
    final mergeDst = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(src.close);
    addTearDown(replaceDst.close);
    addTearDown(mergeDst.close);
    await _seed(src);
    final json = await _exportV2(src);
    expect(const WalletMeltJsonBackupValidator().validate(json).isValid, isTrue);

    for (final entry in {
      replaceDst: RestoreMode.fullReplace,
      mergeDst: RestoreMode.safeMerge,
    }.entries) {
      final result = await _restore(entry.key, tmp, json, entry.value);
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(await _counts(entry.key), await _counts(src));
      final link = await entry.key
          .customSelect("SELECT accountId FROM expenses WHERE id='e1'")
          .getSingle();
      expect(link.read<String?>('accountId'), 'a1');
      final other = await entry.key
          .customSelect("SELECT accountId FROM expenses WHERE id='e2'")
          .getSingle();
      expect(other.read<String?>('accountId'), isNull);
      expect(
          await entry.key.customSelect('PRAGMA foreign_key_check;').get(),
          isEmpty);
    }
  });

  test('full replace over a DB with accounts replaces them without FK errors',
      () async {
    final src = local.WalletMeltDatabase(NativeDatabase.memory());
    final dst = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(src.close);
    addTearDown(dst.close);
    await _seed(src);
    final json = await _exportV2(src);

    await dst.customStatement(
        "INSERT INTO accounts (id, name, type, currency, openingBalanceMinorUnits, openingDate, createdAt, updatedAt) VALUES ('a_old','Old','cash','PKR',1,'2026-06-01T00:00:00.000','$_ts','$_ts');");
    await dst.customStatement(
        "INSERT INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt) VALUES ('c_o','O','i','#000',0,'$_ts','$_ts');");
    await dst.customStatement(
        "INSERT INTO expenses (id, amount, currency, categoryId, title, accountId, date, isRecurring, itemTotalMismatchApproved, createdAt, updatedAt) VALUES ('e_o',9,'PKR','c_o','Old','a_old','2026-06-01',0,0,'$_ts','$_ts');");
    await dst.customStatement(
        "INSERT INTO account_movements (id, accountId, kind, amountMinorUnits, date, createdAt, updatedAt) VALUES ('m_o','a_old','adjustment',5,'2026-06-02','$_ts','$_ts');");

    final result = await _restore(dst, tmp, json, RestoreMode.fullReplace);
    expect(result.success, isTrue, reason: result.errorMessage);
    expect(await _counts(dst), await _counts(src));
    final old = await dst
        .customSelect("SELECT COUNT(*) c FROM accounts WHERE id='a_old'")
        .getSingle();
    expect(old.read<int>('c'), 0);
  });

  test('a pre-accounts v2 backup (no account keys) still validates and restores',
      () async {
    final src = local.WalletMeltDatabase(NativeDatabase.memory());
    final dst = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(src.close);
    addTearDown(dst.close);
    await _seed(src);
    final json = await _exportV2(src, legacyExtended: true);
    expect(json, isNot(contains('expense_account_links')));
    expect(const WalletMeltJsonBackupValidator().validate(json).isValid, isTrue);

    final result = await _restore(dst, tmp, json, RestoreMode.fullReplace);
    expect(result.success, isTrue, reason: result.errorMessage);
    final counts = await _counts(dst);
    expect(counts['accounts'], 0);
    expect(counts['account_movements'], 0);
    expect(counts['expenses'], 2);
    final link = await dst
        .customSelect("SELECT accountId FROM expenses WHERE id='e1'")
        .getSingle();
    expect(link.read<String?>('accountId'), isNull);
  });
}
