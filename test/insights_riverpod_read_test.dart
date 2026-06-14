import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' as local;
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/providers/category_providers.dart';
import 'package:wallet_melt/src/providers/database_providers.dart';
import 'package:wallet_melt/src/screens/insights/insights_screen.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';

void main() {
  testWidgets('Insights budget section reads category and budget data from Riverpod', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final database = local.WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await DriftBudgetRepository(database).upsert(
      categoryId: 'grocery',
      amount: 3000,
      currency: 'PKR',
      month: '2026-06',
    );

    const grocery = Category(
      id: 'grocery',
      name: 'Grocery',
      icon: 'shopping_basket',
      color: '#8FD6B5',
      isDefault: true,
      createdAt: '2026-06-01T00:00:00.000',
      updatedAt: '2026-06-01T00:00:00.000',
    );
    final appState = AppState()
      ..isLoading = false
      ..selectedMonth = DateTime(2026, 6)
      ..categories = const [grocery]
      ..expenses = const [
        Expense(
          id: 'expense-1',
          amount: 5000,
          currency: 'PKR',
          categoryId: 'grocery',
          title: 'Grocery run',
          date: '2026-06-04T00:00:00.000',
          isRecurring: false,
          createdAt: '2026-06-04T10:00:00.000',
          updatedAt: '2026-06-04T10:00:00.000',
        ),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletMeltDatabaseProvider.overrideWith((ref) async => database),
          categoriesProvider.overrideWith((ref) async {
            return const [grocery];
          }),
        ],
        child: legacy_provider.ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(home: InsightsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('No categories available.'), findsNothing);
    expect(find.text('Rs 5,000 / Rs 3,000'), findsOneWidget);
  });
}
