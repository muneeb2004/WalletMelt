import 'package:drift/drift.dart';

import '../../data/local/wallet_melt_database.dart' as local;

/// Backup v2 "extended" section: every table the legacy v1 sections
/// (expenses, grocery_items, categories, budgets, monthly_budgets) do not own.
///
/// Rows are exported and imported through Drift's generated `toJson`/`fromJson`
/// so the section cannot drift from the schema. Device-local bookkeeping
/// (`migration_audit`, `sync_metadata`) is intentionally excluded.
class BackupExtendedTables {
  const BackupExtendedTables._();

  /// Top-level backup key that holds the extended section.
  static const String sectionKey = 'extended';

  /// Tables in parent-first (insert) order.
  static final List<_TableSpec> _specs = [
    _spec('units', (d) => d.units, local.Unit.fromJson, {'baseUnitId': 'unit'}),
    _spec('payees', (d) => d.payees, local.Payee.fromJson, {},
        naturalKey: 'normalizedName'),
    _spec('stores', (d) => d.stores, local.Store.fromJson,
        {'defaultCategoryId': 'cat'},
        naturalKey: 'normalizedName'),
    _spec('items', (d) => d.items, local.Item.fromJson,
        {'categoryId': 'cat', 'defaultUnitId': 'unit'},
        naturalKey: 'normalizedName'),
    _spec('item_aliases', (d) => d.itemAliases, local.ItemAliase.fromJson,
        {'itemId': 'item'},
        naturalKey: 'normalizedAlias'),
    _spec('debt_records', (d) => d.debtRecords, local.DebtRecord.fromJson,
        {'payeeId': 'payee'}),
    _spec('debt_repayments', (d) => d.debtRepayments,
        local.DebtRepayment.fromJson, {'debtId': 'debt'}),
    _spec('grocery_templates', (d) => d.groceryTemplates,
        local.GroceryTemplate.fromJson, {}),
    _spec('subscriptions', (d) => d.subscriptions, local.Subscription.fromJson,
        {'categoryId': 'cat'}),
    _spec('essential_expense_templates', (d) => d.essentialExpenseTemplates,
        local.EssentialExpenseTemplate.fromJson, {'categoryId': 'cat'}),
    _spec('fuel_template_components', (d) => d.fuelTemplateComponents,
        local.FuelTemplateComponent.fromJson, {'templateId': 'tmpl'}),
    _spec('expense_items', (d) => d.expenseItems, local.ExpenseItem.fromJson, {
      'expenseId': 'exp',
      'itemId': 'item',
      'unitId': 'unit',
      'storeId': 'store',
      'categoryId': 'cat',
    }, expenseScoped: true),
    _spec('receipts', (d) => d.receipts, local.Receipt.fromJson,
        {'expenseId': 'exp'},
        expenseScoped: true),
    _spec('fuel_transactions', (d) => d.fuelTransactions,
        local.FuelTransaction.fromJson, {'expenseId': 'exp'},
        expenseScoped: true),
    _spec('fuel_components', (d) => d.fuelComponents,
        local.FuelComponent.fromJson, {'fuelTransactionId': 'ft'}),
  ];

  /// Names of the tables covered by the extended section (parent-first).
  static List<String> get tableNames =>
      _specs.map((s) => s.name).toList(growable: false);

  /// Exports every extended table plus the expense -> store links.
  static Future<Map<String, Object?>> export(
      local.WalletMeltDatabase db) async {
    final tables = <String, Object?>{};
    for (final spec in _specs) {
      tables[spec.name] = await spec.export(db);
    }
    final links = await db
        .customSelect(
            'SELECT id, storeId FROM expenses WHERE storeId IS NOT NULL ORDER BY id')
        .get();
    return {
      'tables': tables,
      'expense_store_links': [
        for (final row in links)
          {
            'expense_id': row.read<String>('id'),
            'store_id': row.read<String>('storeId'),
          },
      ],
    };
  }

  /// Per-table row counts of an extended section (for preview / validation).
  static Map<String, int> counts(Object? section) {
    final result = <String, int>{};
    if (section is! Map) return result;
    final tables = section['tables'];
    if (tables is! Map) return result;
    for (final name in tableNames) {
      final rows = tables[name];
      if (rows is List) result[name] = rows.length;
    }
    return result;
  }

  /// Structural validation of an extended section; returns an error or null.
  static String? validate(Object? section) {
    if (section is! Map) return 'extended section is not a JSON object.';
    final tables = section['tables'];
    if (tables is! Map) return 'extended.tables is not a JSON object.';
    for (final name in tableNames) {
      final rows = tables[name];
      if (rows is! List) return 'extended.tables.$name is not an array.';
      for (final row in rows) {
        if (row is! Map) {
          return 'extended.tables.$name contains a non-object row.';
        }
        if (row['id'] is! String) {
          return 'extended.tables.$name contains a row without a string id.';
        }
      }
    }
    if (section['expense_store_links'] is! List) {
      return 'extended.expense_store_links is not an array.';
    }
    return null;
  }

  /// Imports the extended section inside the caller's transaction.
  ///
  /// [replace] is true for a full replace into an emptied database. Otherwise
  /// rows are merged: natural-key collisions map to the existing local row, and
  /// expense-scoped child rows are only imported for expenses in
  /// [importedExpenseIds] (never for pre-existing expenses).
  static Future<Map<String, int>> importInto(
    local.WalletMeltDatabase db,
    Map<String, Object?> section, {
    required bool replace,
    required Map<String, String> categoryMap,
    required Map<String, String> expenseMap,
    required Set<String> importedExpenseIds,
  }) async {
    final tables = (section['tables'] as Map).cast<String, Object?>();
    final maps = <String, Map<String, String>>{
      'cat': categoryMap,
      'exp': expenseMap,
      'unit': {},
      'payee': {},
      'store': {},
      'item': {},
      'debt': {},
      'tmpl': {},
      'ft': {},
    };
    final skippedTransactions = <String>{};
    final inserted = <String, int>{};

    for (final spec in _specs) {
      final rows = ((tables[spec.name] as List?) ?? const [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      if (spec.name == 'units') {
        // Self-referencing FK: insert base units first.
        rows.sort((a, b) =>
            (a['baseUnitId'] == null ? 0 : 1) -
            (b['baseUnitId'] == null ? 0 : 1));
      }
      var count = 0;
      for (final row in rows) {
        final sourceId = row['id'] as String;
        final sourceTransactionId = row['fuelTransactionId'] as String?;
        spec.remap(row, maps);

        if (spec.expenseScoped) {
          final expenseId = row['expenseId'] as String?;
          if (expenseId == null) continue;
          if (!replace && !importedExpenseIds.contains(expenseId)) continue;
          if (!await _exists(db, 'expenses', 'id', expenseId)) continue;
        }

        // Natural-key collision: reuse the existing local row.
        final naturalKey = spec.naturalKey;
        if (naturalKey != null && row[naturalKey] != null) {
          final existing =
              await _firstId(db, spec.name, naturalKey, row[naturalKey]);
          if (existing != null) {
            _recordMapping(maps, spec.name, sourceId, existing);
            continue;
          }
        }

        // Duplicate guards for rows the core path may already have derived.
        if (spec.name == 'expense_items' && await _expenseItemExists(db, row)) {
          continue;
        }
        if (spec.name == 'receipts' &&
            await _existsPair(db, 'receipts', 'expenseId', row['expenseId'],
                'uri', row['uri'])) {
          continue;
        }
        if (spec.name == 'fuel_transactions') {
          final existing = await _firstId(
              db, 'fuel_transactions', 'expenseId', row['expenseId']);
          if (existing != null && existing != sourceId) {
            maps['ft']![sourceId] = existing;
            skippedTransactions.add(sourceId);
            continue;
          }
        }
        if (spec.name == 'fuel_components' &&
            skippedTransactions.contains(sourceTransactionId)) {
          continue;
        }

        if (await spec.insert(db, row)) {
          count++;
          _recordMapping(maps, spec.name, sourceId, row['id'] as String);
        }
      }
      inserted[spec.name] = count;
    }

    // Expense -> store links (stores are restored after expenses).
    final links = (section['expense_store_links'] as List?) ?? const [];
    var linked = 0;
    for (final raw in links) {
      final link = Map<String, dynamic>.from(raw as Map);
      final sourceExpense = link['expense_id'] as String;
      final targetExpense = expenseMap[sourceExpense] ?? sourceExpense;
      if (!replace && !importedExpenseIds.contains(targetExpense)) continue;
      final sourceStore = link['store_id'] as String;
      final storeId = maps['store']![sourceStore] ?? sourceStore;
      if (!await _exists(db, 'stores', 'id', storeId)) continue;
      if (!await _exists(db, 'expenses', 'id', targetExpense)) continue;
      await db.customStatement(
          'UPDATE expenses SET storeId = ? WHERE id = ?;',
          [storeId, targetExpense]);
      linked++;
    }
    inserted['expense_store_links'] = linked;
    return inserted;
  }

  // ---- helpers ------------------------------------------------------------

  static void _recordMapping(Map<String, Map<String, String>> maps,
      String table, String source, String target) {
    final key = switch (table) {
      'units' => 'unit',
      'payees' => 'payee',
      'stores' => 'store',
      'items' => 'item',
      'debt_records' => 'debt',
      'essential_expense_templates' => 'tmpl',
      'fuel_transactions' => 'ft',
      _ => null,
    };
    if (key != null) maps[key]![source] = target;
  }

  static Future<bool> _exists(local.WalletMeltDatabase db, String table,
      String column, Object? value) async {
    final r = await db.customSelect(
        'SELECT 1 AS x FROM $table WHERE $column = ? LIMIT 1;',
        variables: [Variable(value)]).get();
    return r.isNotEmpty;
  }

  static Future<String?> _firstId(local.WalletMeltDatabase db, String table,
      String column, Object? value) async {
    final r = await db.customSelect(
        'SELECT id FROM $table WHERE $column = ? LIMIT 1;',
        variables: [Variable(value)]).get();
    return r.isEmpty ? null : r.first.read<String>('id');
  }

  static Future<bool> _existsPair(local.WalletMeltDatabase db, String table,
      String c1, Object? v1, String c2, Object? v2) async {
    final r = await db.customSelect(
        'SELECT 1 AS x FROM $table WHERE $c1 = ? AND $c2 = ? LIMIT 1;',
        variables: [Variable(v1), Variable(v2)]).get();
    return r.isNotEmpty;
  }

  static Future<bool> _expenseItemExists(
      local.WalletMeltDatabase db, Map<String, dynamic> row) async {
    final r = await db.customSelect(
        'SELECT 1 AS x FROM expense_items WHERE id = ? OR (expenseId = ? AND nameSnapshot = ? AND totalPrice = ?) LIMIT 1;',
        variables: [
          Variable(row['id']),
          Variable(row['expenseId']),
          Variable(row['nameSnapshot']),
          Variable(row['totalPrice']),
        ]).get();
    return r.isNotEmpty;
  }
}

class _TableSpec {
  _TableSpec({
    required this.name,
    required this.export,
    required this.insert,
    required this.remapColumns,
    required this.naturalKey,
    required this.expenseScoped,
  });

  final String name;
  final Future<List<Map<String, Object?>>> Function(local.WalletMeltDatabase)
      export;

  /// Returns true when the row was inserted, false on primary-key collision.
  final Future<bool> Function(local.WalletMeltDatabase, Map<String, dynamic>)
      insert;
  final Map<String, String> remapColumns;
  final String? naturalKey;
  final bool expenseScoped;

  void remap(Map<String, dynamic> row, Map<String, Map<String, String>> maps) {
    remapColumns.forEach((column, mapKey) {
      final value = row[column];
      if (value is String) {
        row[column] = maps[mapKey]![value] ?? value;
      }
    });
  }
}

_TableSpec _spec<T extends Table, D extends DataClass>(
  String name,
  TableInfo<T, D> Function(local.WalletMeltDatabase) table,
  D Function(Map<String, dynamic>) fromJson,
  Map<String, String> remapColumns, {
  String? naturalKey,
  bool expenseScoped = false,
}) {
  return _TableSpec(
    name: name,
    remapColumns: remapColumns,
    naturalKey: naturalKey,
    expenseScoped: expenseScoped,
    export: (db) async {
      final rows = await db.select(table(db)).get();
      final json = rows.map((r) => r.toJson()).toList();
      json.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
      return json;
    },
    insert: (db, row) async {
      final exists = await db.customSelect(
          'SELECT 1 AS x FROM $name WHERE id = ? LIMIT 1;',
          variables: [Variable(row['id'])]).get();
      if (exists.isNotEmpty) return false;
      await db.into(table(db)).insert(fromJson(row) as Insertable<D>);
      return true;
    },
  );
}
