import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../../../types/category.dart' as domain;

class DriftCategoryRepository {
  DriftCategoryRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  Future<List<domain.Category>> listCategories() async {
    final rows = await _db.customSelect(
      '''
SELECT id, name, icon, color, isDefault, createdAt, updatedAt
FROM categories
ORDER BY isDefault DESC, name COLLATE NOCASE ASC;
''',
      readsFrom: {_db.categories},
    ).get();
    return rows.map((row) {
      return domain.Category(
        id: row.read<String>('id'),
        name: row.read<String>('name'),
        icon: row.read<String>('icon'),
        color: row.read<String>('color'),
        isDefault: row.read<bool>('isDefault'),
        createdAt: row.read<String>('createdAt'),
        updatedAt: row.read<String>('updatedAt'),
      );
    }).toList();
  }

  Future<domain.Category?> getById(String id) async {
    final row = await (_db.select(_db.categories)
          ..where((category) => category.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  Future<domain.Category> createCustom({
    required String name,
    required String icon,
    required String color,
  }) async {
    final now = DateTime.now().toIso8601String();
    final category = domain.Category(
      id: _uuid.v4(),
      name: name.trim(),
      icon: icon,
      color: color,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.categories).insert(
          local.CategoriesCompanion.insert(
            id: category.id,
            name: category.name,
            icon: category.icon,
            color: category.color,
            isDefault: category.isDefault,
            createdAt: category.createdAt,
            updatedAt: category.updatedAt,
          ),
        );
    return category;
  }

  /// Changes a category's name, icon and colour. Default categories can be
  /// restyled too; their id (and so every expense, budget and template that
  /// points at it) never changes. Returns null when [id] does not exist.
  Future<domain.Category?> updateDetails(
    String id, {
    String? name,
    String? icon,
    String? color,
  }) async {
    final existing = await getById(id);
    if (existing == null) return null;
    final trimmed = name?.trim();
    final updated = existing.copyWith(
      name: (trimmed == null || trimmed.isEmpty) ? existing.name : trimmed,
      icon: icon ?? existing.icon,
      color: color ?? existing.color,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      local.CategoriesCompanion(
        name: Value(updated.name),
        icon: Value(updated.icon),
        color: Value(updated.color),
        updatedAt: Value(updated.updatedAt),
      ),
    );
    return updated;
  }

  /// Points every category using [iconId] at [replacement].
  Future<int> replaceIcon(String iconId, String replacement) {
    return (_db.update(_db.categories)..where((c) => c.icon.equals(iconId)))
        .write(local.CategoriesCompanion(
      icon: Value(replacement),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  domain.Category _toDomain(local.Category row) {
    return domain.Category(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      isDefault: row.isDefault,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
