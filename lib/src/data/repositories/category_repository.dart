import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../types/category.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final Database _db;
  final _uuid = const Uuid();

  Future<List<Category>> listCategories() async {
    final rows = await _db.query('categories',
        orderBy: 'isDefault DESC, name COLLATE NOCASE ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(String id) async {
    final rows = await _db.query('categories',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<Category> createCustom({
    required String name,
    required String icon,
    required String color,
  }) async {
    final now = DateTime.now().toIso8601String();
    final category = Category(
      id: _uuid.v4(),
      name: name.trim(),
      icon: icon,
      color: color,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert('categories', category.toMap());
    return category;
  }
}
