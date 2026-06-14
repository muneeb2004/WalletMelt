import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/providers/category_providers.dart';
import 'package:wallet_melt/src/providers/database_providers.dart';
import 'package:wallet_melt/src/providers/repository_providers.dart';

void main() {
  test('categoriesProvider returns V1-compatible sorted categories', () async {
    final container = _containerWithMemoryDatabase();
    addTearDown(container.dispose);

    final repository =
        await container.read(driftCategoryRepositoryProvider.future);
    await repository.createCustom(
        name: 'Zoo Custom', icon: 'more_horiz', color: '#111111');
    await repository.createCustom(
        name: 'Alpha Custom', icon: 'more_horiz', color: '#222222');

    container.invalidate(categoriesProvider);
    final categories = await container.read(categoriesProvider.future);
    final defaultCategories =
        categories.where((category) => category.isDefault).toList();
    final customCategories =
        categories.where((category) => !category.isDefault).toList();

    expect(defaultCategories, isNotEmpty);
    expect(customCategories.map((category) => category.name),
        ['Alpha Custom', 'Zoo Custom']);
    expect(categories.indexOf(defaultCategories.last),
        lessThan(categories.indexOf(customCategories.first)));
    expect(categories.map((category) => category.id), contains('grocery'));
  });

  test('categoryByIdProvider resolves categories from categoriesProvider',
      () async {
    final container = _containerWithMemoryDatabase();
    addTearDown(container.dispose);

    final category =
        await container.read(categoryByIdProvider('grocery').future);

    expect(category?.name, 'Grocery');
    expect(category?.icon, 'shopping_basket');
    expect(category?.color, '#8FD6B5');
  });
}

ProviderContainer _containerWithMemoryDatabase() {
  return ProviderContainer(
    overrides: [
      walletMeltDatabaseProvider.overrideWith((ref) async {
        final database = WalletMeltDatabase(NativeDatabase.memory());
        ref.onDispose(database.close);
        return database;
      }),
    ],
  );
}
