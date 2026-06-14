import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';

void main() {
  test('loads seeded default categories in V1 sort order and creates custom categories', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftCategoryRepository(db);

    final defaults = await repository.listCategories();
    expect(defaults.first.isDefault, isTrue);
    expect(defaults.map((category) => category.id), containsAll(['electricity', 'gas', 'grocery', 'rent']));

    final custom = await repository.createCustom(name: '  Household Care  ', icon: 'cleaning_services', color: '#123456');
    expect(custom.name, 'Household Care');
    expect(custom.isDefault, isFalse);

    final loaded = await repository.getById(custom.id);
    expect(loaded?.icon, 'cleaning_services');
    expect(loaded?.color, '#123456');

    final categories = await repository.listCategories();
    final firstCustomIndex = categories.indexWhere((category) => !category.isDefault);
    final lastDefaultIndex = categories.lastIndexWhere((category) => category.isDefault);
    expect(firstCustomIndex, greaterThan(lastDefaultIndex));
  });
}
