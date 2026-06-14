import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallet_melt/src/app/wallet_melt_app.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_item_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_receipt_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_store_repository.dart';
import 'package:wallet_melt/src/data/repositories/expense_repository.dart';
import 'package:wallet_melt/src/providers/database_providers.dart';
import 'package:wallet_melt/src/providers/repository_providers.dart';
import 'package:wallet_melt/src/providers/settings_providers.dart';
import 'package:wallet_melt/src/services/receipt_storage/receipt_storage_service.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';

void main() {
  testWidgets(
      'WalletMeltBootstrap includes ProviderScope without breaking startup',
      (tester) async {
    await tester.pumpWidget(const WalletMeltBootstrap());

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('walletMeltDatabaseProvider resolves a Drift database', () async {
    final container = ProviderContainer(
      overrides: [
        walletMeltDatabaseProvider.overrideWith((ref) async {
          final database = WalletMeltDatabase(NativeDatabase.memory());
          ref.onDispose(database.close);
          return database;
        }),
      ],
    );
    addTearDown(container.dispose);

    final database = await container.read(walletMeltDatabaseProvider.future);
    final units = await database.select(database.units).get();

    expect(database, isA<WalletMeltDatabase>());
    expect(units.map((unit) => unit.id), contains('piece'));
  });

  test('service providers resolve successfully', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(settingsServiceProvider), isA<SettingsService>());
    expect(container.read(receiptStorageServiceProvider),
        isA<ReceiptStorageService>());
  });

  test(
      'sqflite repository providers resolve when supplied an existing database dependency',
      () async {
    final container = ProviderContainer(
      overrides: [
        sqfliteDatabaseProvider.overrideWith((ref) async => _FakeDatabase()),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(categoryRepositoryProvider.future),
        isA<CategoryRepository>());
    expect(await container.read(expenseRepositoryProvider.future),
        isA<ExpenseRepository>());
    expect(await container.read(budgetRepositoryProvider.future),
        isA<BudgetRepository>());
  });

  test(
      'Drift repository providers resolve when supplied a Drift database dependency',
      () async {
    final container = ProviderContainer(
      overrides: [
        walletMeltDatabaseProvider.overrideWith((ref) async {
          final database = WalletMeltDatabase(NativeDatabase.memory());
          ref.onDispose(database.close);
          return database;
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(driftCategoryRepositoryProvider.future),
        isA<DriftCategoryRepository>());
    expect(await container.read(driftExpenseRepositoryProvider.future),
        isA<DriftExpenseRepository>());
    expect(await container.read(driftBudgetRepositoryProvider.future),
        isA<DriftBudgetRepository>());
    expect(await container.read(driftItemRepositoryProvider.future),
        isA<DriftItemRepository>());
    expect(await container.read(driftStoreRepositoryProvider.future),
        isA<DriftStoreRepository>());
    expect(await container.read(driftReceiptRepositoryProvider.future),
        isA<DriftReceiptRepository>());
  });
}

class _FakeDatabase implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
