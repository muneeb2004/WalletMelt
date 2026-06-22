import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' hide GroceryTemplate;
import 'package:wallet_melt/src/data/repositories/drift/drift_grocery_template_repository.dart';
import 'package:wallet_melt/src/types/grocery_template.dart';

void main() {
  test('GroceryTemplate CRUD operations', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftGroceryTemplateRepository(db);

    final template = GroceryTemplate(
      id: 'template-1',
      name: 'Ramadan Essentials',
      items: const ['Rice', 'Flour', 'Dates', 'Sugar'],
      createdAt: DateTime.now().toIso8601String(),
    );

    await repository.create(template);

    final all = await repository.listAll();
    expect(all.length, 1);
    expect(all.first.name, 'Ramadan Essentials');
    expect(all.first.items, const ['Rice', 'Flour', 'Dates', 'Sugar']);

    await repository.delete('template-1');
    final afterDelete = await repository.listAll();
    expect(afterDelete, isEmpty);
  });
}
