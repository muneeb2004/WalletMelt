import 'dart:convert';
import 'package:drift/drift.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../../../types/grocery_template.dart' as domain;

class DriftGroceryTemplateRepository {
  DriftGroceryTemplateRepository(this._db);

  final local.WalletMeltDatabase _db;

  Future<List<domain.GroceryTemplate>> listAll() async {
    final rows = await (_db.select(_db.groceryTemplates)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.GroceryTemplate> create(domain.GroceryTemplate template) async {
    final row = local.GroceryTemplatesCompanion.insert(
      id: template.id,
      name: template.name,
      items: jsonEncode(template.items),
      createdAt: template.createdAt,
    );
    await _db.into(_db.groceryTemplates).insert(row);
    return template;
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.groceryTemplates)..where((t) => t.id.equals(id))).go();
  }

  domain.GroceryTemplate _toDomain(local.GroceryTemplate row) {
    final List<dynamic> decoded = jsonDecode(row.items) as List<dynamic>;
    final items = decoded.map((e) => e.toString()).toList();
    return domain.GroceryTemplate(
      id: row.id,
      name: row.name,
      items: items,
      createdAt: row.createdAt,
    );
  }
}
