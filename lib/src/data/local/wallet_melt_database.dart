import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../constants/categories.dart';
import '../schema/database_schema.dart';

part 'wallet_melt_database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  BoolColumn get isDefault => boolean().named('isDefault')();
  TextColumn get createdAt => text().named('createdAt')();
  TextColumn get updatedAt => text().named('updatedAt')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  TextColumn get categoryId => text().named('categoryId').references(Categories, #id)();
  TextColumn get title => text()();
  TextColumn get vendor => text().nullable()();
  TextColumn get storeId => text().named('storeId').nullable().references(Stores, #id)();
  TextColumn get date => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptImageUri => text().named('receiptImageUri').nullable()();
  BoolColumn get isRecurring => boolean().named('isRecurring').withDefault(const Constant(false))();
  TextColumn get recurrenceFrequency => text().named('recurrenceFrequency').nullable()();
  TextColumn get itemizationStatus => text().named('itemizationStatus').nullable()();
  BoolColumn get itemTotalMismatchApproved => boolean().named('itemTotalMismatchApproved').withDefault(const Constant(false))();
  TextColumn get createdAt => text().named('createdAt')();
  TextColumn get updatedAt => text().named('updatedAt')();
  TextColumn get deletedAt => text().named('deletedAt').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class GroceryItems extends Table {
  @override
  String get tableName => 'grocery_items';

  TextColumn get id => text()();
  TextColumn get expenseId => text().named('expenseId').references(Expenses, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get createdAt => text().named('createdAt')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CategoryBudgets extends Table {
  @override
  String get tableName => 'category_budgets';

  TextColumn get id => text()();
  TextColumn get categoryId => text().named('categoryId').references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  TextColumn get month => text()();
  TextColumn get createdAt => text().named('createdAt')();
  TextColumn get updatedAt => text().named('updatedAt')();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {categoryId, month},
      ];
}

class SyncMetadata extends Table {
  @override
  String get tableName => 'sync_metadata';

  TextColumn get entityType => text().named('entityType')();
  TextColumn get entityId => text().named('entityId')();
  IntColumn get localVersion => integer().named('localVersion').withDefault(const Constant(1))();
  TextColumn get remoteId => text().named('remoteId').nullable()();
  TextColumn get lastSyncedAt => text().named('lastSyncedAt').nullable()();
  TextColumn get syncState => text().named('syncState').withDefault(const Constant('local_only'))();

  @override
  Set<Column<Object>> get primaryKey => {entityType, entityId};
}

class Units extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get abbreviation => text()();
  TextColumn get dimension => text()();
  TextColumn get baseUnitId => text().named('baseUnitId').nullable().references(Units, #id)();
  RealColumn get factorToBase => real().named('factorToBase').nullable()();
  BoolColumn get isDefault => boolean().named('isDefault').withDefault(const Constant(true))();
  TextColumn get createdAt => text().named('createdAt')();
  TextColumn get updatedAt => text().named('updatedAt')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().named('normalizedName')();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text().named('createdAt')();
  TextColumn get updatedAt => text().named('updatedAt')();
  TextColumn get archivedAt => text().named('archivedAt').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {normalizedName},
      ];
}

class Items extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().named('normalizedName')();
  TextColumn get defaultUnitId => text().named('defaultUnitId').nullable().references(Units, #id)();
  TextColumn get categoryId => text().named('categoryId').nullable().references(Categories, #id)();
  TextColumn get createdAt => text().named('createdAt')();
  TextColumn get updatedAt => text().named('updatedAt')();
  TextColumn get archivedAt => text().named('archivedAt').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {normalizedName},
      ];
}

class ItemAliases extends Table {
  @override
  String get tableName => 'item_aliases';

  TextColumn get id => text()();
  TextColumn get itemId => text().named('itemId').references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get alias => text()();
  TextColumn get normalizedAlias => text().named('normalizedAlias')();
  TextColumn get createdAt => text().named('createdAt')();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {normalizedAlias},
      ];
}

class ExpenseItems extends Table {
  @override
  String get tableName => 'expense_items';

  TextColumn get id => text()();
  TextColumn get expenseId => text().named('expenseId').references(Expenses, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemId => text().named('itemId').nullable().references(Items, #id)();
  TextColumn get nameSnapshot => text().named('nameSnapshot')();
  RealColumn get quantity => real().nullable()();
  TextColumn get unitId => text().named('unitId').nullable().references(Units, #id)();
  RealColumn get unitPrice => real().named('unitPrice').nullable()();
  RealColumn get totalPrice => real().named('totalPrice')();
  TextColumn get currency => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get storeId => text().named('storeId').nullable().references(Stores, #id)();
  TextColumn get dateOverride => text().named('dateOverride').nullable()();
  TextColumn get categoryId => text().named('categoryId').nullable().references(Categories, #id)();
  TextColumn get subcategory => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text().named('createdAt')();
  TextColumn get updatedAt => text().named('updatedAt')();
  TextColumn get deletedAt => text().named('deletedAt').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Receipts extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text().named('expenseId').references(Expenses, #id, onDelete: KeyAction.cascade)();
  TextColumn get uri => text()();
  TextColumn get mimeType => text().named('mimeType').nullable()();
  IntColumn get fileSizeBytes => integer().named('fileSizeBytes').nullable()();
  TextColumn get createdAt => text().named('createdAt')();
  TextColumn get deletedAt => text().named('deletedAt').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MigrationAudit extends Table {
  @override
  String get tableName => 'migration_audit';

  TextColumn get id => text()();
  IntColumn get fromVersion => integer().named('fromVersion')();
  IntColumn get toVersion => integer().named('toVersion')();
  TextColumn get startedAt => text().named('startedAt')();
  TextColumn get completedAt => text().named('completedAt').nullable()();
  TextColumn get status => text()();
  TextColumn get errorMessage => text().named('errorMessage').nullable()();
  TextColumn get preMigrationBackupPath => text().named('preMigrationBackupPath').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class V1MigrationMetrics {
  const V1MigrationMetrics({
    required this.expenseCount,
    required this.categoryCount,
    required this.budgetCount,
    required this.groceryItemCount,
    required this.activeExpenseTotal,
    required this.softDeletedExpenseCount,
    required this.receiptPathCount,
  });

  final int expenseCount;
  final int categoryCount;
  final int budgetCount;
  final int groceryItemCount;
  final double activeExpenseTotal;
  final int softDeletedExpenseCount;
  final int receiptPathCount;
}

@DriftDatabase(
  tables: [
    Categories,
    Expenses,
    GroceryItems,
    CategoryBudgets,
    SyncMetadata,
    Units,
    Stores,
    Items,
    ItemAliases,
    ExpenseItems,
    Receipts,
    MigrationAudit,
  ],
)
class WalletMeltDatabase extends _$WalletMeltDatabase {
  WalletMeltDatabase(super.executor, {this.preMigrationBackupPath});

  static const currentSchemaVersion = 2;

  final String? preMigrationBackupPath;

  // Singleton cache: ensures that all callers of [open()] receive the same
  // WalletMeltDatabase instance. This prevents the "database opened twice"
  // Drift warning that arises when both AppState and Riverpod providers call
  // open() independently during app boot.
  static WalletMeltDatabase? _singleton;
  static Future<WalletMeltDatabase>? _singletonFuture;

  static Future<WalletMeltDatabase> open() async {
    if (_singleton != null) return _singleton!;
    // Guard against concurrent open() calls during boot by caching the Future.
    _singletonFuture ??= _openImpl();
    _singleton = await _singletonFuture;
    return _singleton!;
  }

  static Future<WalletMeltDatabase> _openImpl() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, DatabaseSchema.databaseName);
    return openAtPath(path);
  }

  /// Resets the cached singleton. **Only call this in tests.**
  @visibleForTesting
  static void resetSingletonForTesting() {
    _singleton = null;
    _singletonFuture = null;
  }

  static Future<WalletMeltDatabase> openAtPath(String path) async {
    final backupPath = await createPreV2BackupIfNeeded(path);
    return WalletMeltDatabase(
      NativeDatabase.createInBackground(File(path)),
      preMigrationBackupPath: backupPath,
    );
  }

  static Future<String?> createPreV2BackupIfNeeded(String path) async {
    final dbFile = File(path);
    if (!await dbFile.exists()) return null;

    final existingVersion = _readUserVersion(path);
    if (existingVersion <= 0 || existingVersion >= currentSchemaVersion) {
      return null;
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(
      dbFile.parent.path,
      'wallet_melt.pre_v2_$timestamp.db',
    );
    await dbFile.copy(backupPath);

    for (final suffix in ['-wal', '-shm']) {
      final sidecar = File('$path$suffix');
      if (await sidecar.exists()) {
        await sidecar.copy('$backupPath$suffix');
      }
    }

    return backupPath;
  }

  static int _readUserVersion(String path) {
    final db = sqlite3.sqlite3.open(path);
    try {
      final result = db.select('PRAGMA user_version;');
      return result.first['user_version'] as int;
    } finally {
      db.close();
    }
  }

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
          await _seedDefaultUnits();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _upgradeFromV1ToV2(m, from, to);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  Future<void> _upgradeFromV1ToV2(Migrator m, int from, int to) async {
    final before = await readV1MigrationMetrics();

    await m.createTable(units);
    await m.createTable(stores);
    await m.createTable(items);
    await m.createTable(itemAliases);
    await m.addColumn(expenses, expenses.storeId);
    await m.addColumn(expenses, expenses.itemizationStatus);
    await m.addColumn(expenses, expenses.itemTotalMismatchApproved);
    await m.createTable(expenseItems);
    await m.createTable(receipts);
    await m.createTable(migrationAudit);

    await _seedDefaultUnits();

    final auditId = 'v1_to_v2_${DateTime.now().microsecondsSinceEpoch}';
    await into(migrationAudit).insert(
      MigrationAuditCompanion.insert(
        id: auditId,
        fromVersion: from,
        toVersion: to,
        startedAt: DateTime.now().toIso8601String(),
        status: 'running',
        preMigrationBackupPath: Value(preMigrationBackupPath),
      ),
    );

    try {
      await _migrateLegacyGroceryItems();
      await _migrateLegacyReceiptPaths();

      final after = await readV1MigrationMetrics();
      await validateV1ToV2Migration(before: before, after: after);

      await (update(migrationAudit)..where((row) => row.id.equals(auditId))).write(
        MigrationAuditCompanion(
          completedAt: Value(DateTime.now().toIso8601String()),
          status: const Value('completed'),
        ),
      );
    } catch (error) {
      await (update(migrationAudit)..where((row) => row.id.equals(auditId))).write(
        MigrationAuditCompanion(
          completedAt: Value(DateTime.now().toIso8601String()),
          status: const Value('failed'),
          errorMessage: Value(error.toString()),
        ),
      );
      rethrow;
    }
  }

  Future<V1MigrationMetrics> readV1MigrationMetrics() async {
    return V1MigrationMetrics(
      expenseCount: await _count('expenses'),
      categoryCount: await _count('categories'),
      budgetCount: await _count('category_budgets'),
      groceryItemCount: await _count('grocery_items'),
      activeExpenseTotal: await _activeExpenseTotal(),
      softDeletedExpenseCount: await _countWhere('expenses', 'deletedAt IS NOT NULL'),
      receiptPathCount: await _countWhere(
        'expenses',
        "receiptImageUri IS NOT NULL AND TRIM(receiptImageUri) <> ''",
      ),
    );
  }

  Future<void> validateV1ToV2Migration({
    required V1MigrationMetrics before,
    required V1MigrationMetrics after,
  }) async {
    final migratedExpenseItemCount = await _count('expense_items');
    final migratedReceiptCount = await _matchingReceiptPathCount();

    final failures = <String>[];
    if (before.expenseCount != after.expenseCount) {
      failures.add('expense count changed: ${before.expenseCount} -> ${after.expenseCount}');
    }
    if (before.categoryCount != after.categoryCount) {
      failures.add('category count changed: ${before.categoryCount} -> ${after.categoryCount}');
    }
    if (before.budgetCount != after.budgetCount) {
      failures.add('budget count changed: ${before.budgetCount} -> ${after.budgetCount}');
    }
    if (before.groceryItemCount != migratedExpenseItemCount) {
      failures.add('grocery item migration count mismatch: ${before.groceryItemCount} -> $migratedExpenseItemCount');
    }
    if ((before.activeExpenseTotal - after.activeExpenseTotal).abs() > 0.0001) {
      failures.add('active expense total changed: ${before.activeExpenseTotal} -> ${after.activeExpenseTotal}');
    }
    if (before.softDeletedExpenseCount != after.softDeletedExpenseCount) {
      failures.add('soft deleted row count changed: ${before.softDeletedExpenseCount} -> ${after.softDeletedExpenseCount}');
    }
    if (before.receiptPathCount != after.receiptPathCount || before.receiptPathCount != migratedReceiptCount) {
      failures.add('receipt path preservation mismatch: ${before.receiptPathCount} -> ${after.receiptPathCount}, receipts rows: $migratedReceiptCount');
    }

    if (failures.isNotEmpty) {
      throw StateError('WalletMelt V1 to V2 migration validation failed: ${failures.join('; ')}');
    }
  }

  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now();
    for (final category in buildDefaultCategories(now)) {
      await customStatement(
        '''
INSERT OR IGNORE INTO categories (id, name, icon, color, isDefault, createdAt, updatedAt)
VALUES (?, ?, ?, ?, ?, ?, ?);
''',
        [
          category.id,
          category.name,
          category.icon,
          category.color,
          category.isDefault ? 1 : 0,
          category.createdAt,
          category.updatedAt,
        ],
      );
    }
  }

  Future<void> _seedDefaultUnits() async {
    final now = DateTime.now().toIso8601String();
    const units = [
      ('piece', 'piece', 'pc', 'count', null, null),
      ('dozen', 'dozen', 'doz', 'count', 'piece', 12.0),
      ('kg', 'kilogram', 'kg', 'mass', null, null),
      ('g', 'gram', 'g', 'mass', 'kg', 0.001),
      ('litre', 'litre', 'L', 'volume', null, null),
      ('ml', 'millilitre', 'ml', 'volume', 'litre', 0.001),
      ('pack', 'pack', 'pack', 'package', null, null),
      ('bag', 'bag', 'bag', 'package', null, null),
      ('bottle', 'bottle', 'bottle', 'package', null, null),
      ('bill', 'bill', 'bill', 'service', null, null),
    ];

    for (final unit in units) {
      await customStatement(
        '''
INSERT OR IGNORE INTO units (id, name, abbreviation, dimension, baseUnitId, factorToBase, isDefault, createdAt, updatedAt)
VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?);
''',
        [unit.$1, unit.$2, unit.$3, unit.$4, unit.$5, unit.$6, now, now],
      );
    }
  }

  Future<void> _migrateLegacyGroceryItems() async {
    final rows = await customSelect(
      '''
SELECT gi.id, gi.expenseId, gi.name, gi.amount, gi.createdAt, e.currency, e.categoryId, e.storeId
FROM grocery_items gi
INNER JOIN expenses e ON e.id = gi.expenseId
WHERE TRIM(gi.name) <> '' AND gi.amount > 0;
''',
      readsFrom: {groceryItems, expenses},
    ).get();

    for (final row in rows) {
      final id = row.read<String>('id');
      final expenseId = row.read<String>('expenseId');
      final name = row.read<String>('name').trim();
      final normalizedName = _normalizeName(name);
      final itemId = _legacyItemId(normalizedName);
      final amount = row.read<double>('amount');
      final createdAt = row.read<String>('createdAt');
      final currency = row.read<String>('currency');
      final categoryId = row.readNullable<String>('categoryId');
      final storeId = row.readNullable<String>('storeId');

      await customStatement(
        '''
INSERT OR IGNORE INTO items (id, name, normalizedName, defaultUnitId, categoryId, createdAt, updatedAt, archivedAt)
VALUES (?, ?, ?, NULL, ?, ?, ?, NULL);
''',
        [itemId, name, normalizedName, categoryId, createdAt, createdAt],
      );

      await customStatement(
        '''
INSERT OR IGNORE INTO expense_items (
  id, expenseId, itemId, nameSnapshot, quantity, unitId, unitPrice, totalPrice, currency,
  brand, storeId, dateOverride, categoryId, subcategory, notes, createdAt, updatedAt, deletedAt
)
VALUES (?, ?, ?, ?, NULL, NULL, NULL, ?, ?, NULL, ?, NULL, ?, NULL, NULL, ?, ?, NULL);
''',
        [id, expenseId, itemId, name, amount, currency, storeId, categoryId, createdAt, createdAt],
      );
    }
  }

  Future<void> _migrateLegacyReceiptPaths() async {
    await customStatement(
      '''
INSERT OR IGNORE INTO receipts (id, expenseId, uri, mimeType, fileSizeBytes, createdAt, deletedAt)
SELECT 'legacy_receipt_' || id, id, receiptImageUri, 'image/jpeg', NULL, createdAt, deletedAt
FROM expenses
WHERE receiptImageUri IS NOT NULL AND TRIM(receiptImageUri) <> '';
''',
    );
  }

  Future<int> _count(String tableName) async {
    final row = await customSelect('SELECT COUNT(*) AS value FROM $tableName;').getSingle();
    return row.read<int>('value');
  }

  Future<int> _countWhere(String tableName, String whereClause) async {
    final row = await customSelect('SELECT COUNT(*) AS value FROM $tableName WHERE $whereClause;').getSingle();
    return row.read<int>('value');
  }

  Future<double> _activeExpenseTotal() async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS value FROM expenses WHERE deletedAt IS NULL;',
    ).getSingle();
    return row.read<double>('value');
  }

  Future<int> _matchingReceiptPathCount() async {
    final row = await customSelect(
      '''
SELECT COUNT(*) AS value
FROM receipts r
INNER JOIN expenses e ON e.id = r.expenseId
WHERE e.receiptImageUri IS NOT NULL
  AND TRIM(e.receiptImageUri) <> ''
  AND r.uri = e.receiptImageUri;
''',
    ).getSingle();
    return row.read<int>('value');
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _legacyItemId(String normalizedName) {
    return 'legacy_item_${_stableFnv1a32(normalizedName)}';
  }

  String _stableFnv1a32(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
