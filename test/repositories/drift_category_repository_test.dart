import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';

void main() {
  test(
      'loads seeded default categories in V1 sort order and creates custom categories',
      () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftCategoryRepository(db);

    final defaults = await repository.listCategories();
    expect(defaults.first.isDefault, isTrue);
    expect(defaults.map((category) => category.id),
        containsAll(['electricity', 'gas', 'grocery', 'rent']));

    final custom = await repository.createCustom(
        name: '  Household Care  ',
        icon: 'cleaning_services',
        color: '#123456');
    expect(custom.name, 'Household Care');
    expect(custom.isDefault, isFalse);

    final loaded = await repository.getById(custom.id);
    expect(loaded?.icon, 'cleaning_services');
    expect(loaded?.color, '#123456');

    final categories = await repository.listCategories();
    final firstCustomIndex =
        categories.indexWhere((category) => !category.isDefault);
    final lastDefaultIndex =
        categories.lastIndexWhere((category) => category.isDefault);
    expect(firstCustomIndex, greaterThan(lastDefaultIndex));
  });

  test('updates icon, name and colour of default and custom categories',
      () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftCategoryRepository(db);

    final grocery = await repository.updateDetails('grocery',
        name: '  Food  ', icon: 'utensils', color: '#112233');
    expect(grocery?.id, 'grocery');
    expect(grocery?.name, 'Food');
    expect(grocery?.isDefault, isTrue);
    final loaded = await repository.getById('grocery');
    expect(loaded?.icon, 'utensils');
    expect(loaded?.color, '#112233');

    // A blank name never wipes the existing one.
    final kept = await repository.updateDetails('grocery', name: '   ');
    expect(kept?.name, 'Food');
    expect(await repository.updateDetails('missing', name: 'x'), isNull);
  });

  test('replaceIcon repoints every category using a deleted icon', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftCategoryRepository(db);
    final a = await repository.createCustom(
        name: 'A', icon: 'custom:x.svg', color: '#000000');
    final b = await repository.createCustom(
        name: 'B', icon: 'custom:x.svg', color: '#000000');
    final c = await repository.createCustom(
        name: 'C', icon: 'pizza', color: '#000000');

    expect(await repository.replaceIcon('custom:x.svg', 'other'), 2);
    expect((await repository.getById(a.id))?.icon, 'other');
    expect((await repository.getById(b.id))?.icon, 'other');
    expect((await repository.getById(c.id))?.icon, 'pizza');
  });
}
