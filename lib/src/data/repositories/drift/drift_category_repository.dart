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
