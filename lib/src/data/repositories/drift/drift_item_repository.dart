import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;

class DriftItemRepository {
  DriftItemRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  String normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<local.Item> createOrGet({
    required String name,
    String? categoryId,
    String? defaultUnitId,
  }) async {
    final trimmedName = name.trim();
    final normalizedName = normalizeName(trimmedName);
    final existing = await getByNormalizedName(normalizedName);
    if (existing != null) return existing;

    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    await _db.into(_db.items).insert(
          local.ItemsCompanion.insert(
            id: id,
            name: trimmedName,
            normalizedName: normalizedName,
            defaultUnitId: Value(defaultUnitId),
            categoryId: Value(categoryId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await (_db.select(_db.items)..where((item) => item.id.equals(id))).getSingle());
  }

  Future<local.Item?> getByNormalizedName(String normalizedName) {
    return (_db.select(_db.items)..where((item) => item.normalizedName.equals(normalizedName))).getSingleOrNull();
  }

  Future<void> addAlias({
    required String itemId,
    required String alias,
  }) async {
    final trimmedAlias = alias.trim();
    final normalizedAlias = normalizeName(trimmedAlias);
    final now = DateTime.now().toIso8601String();
    await _db.into(_db.itemAliases).insert(
          local.ItemAliasesCompanion.insert(
            id: _uuid.v4(),
            itemId: itemId,
            alias: trimmedAlias,
            normalizedAlias: normalizedAlias,
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<local.Item?> resolveAlias(String alias) async {
    final normalizedAlias = normalizeName(alias);
    final query = _db.select(_db.items).join([
      innerJoin(_db.itemAliases, _db.itemAliases.itemId.equalsExp(_db.items.id)),
    ])
      ..where(_db.itemAliases.normalizedAlias.equals(normalizedAlias));
    final row = await query.getSingleOrNull();
    return row?.readTable(_db.items);
  }

  Future<List<local.ExpenseItem>> expenseItemsForExpense(String expenseId) {
    return (_db.select(_db.expenseItems)
          ..where((item) => item.expenseId.equals(expenseId))
          ..orderBy([
            (item) => OrderingTerm(expression: item.createdAt),
          ]))
        .get();
  }
}
