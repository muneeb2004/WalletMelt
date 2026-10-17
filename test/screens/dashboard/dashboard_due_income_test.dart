import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_income_repository.dart';
import 'package:wallet_melt/src/screens/dashboard/dashboard_screen.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/income.dart';
import 'package:wallet_melt/src/types/settings.dart';

class _Settings extends SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}

void main() {
  Widget harness(AppState state) {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
    ]);
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp.router(
        theme: WalletMeltTheme.light(),
        routerConfig: router,
      ),
    );
  }

  Future<(AppState, Account)> setUp(WidgetTester tester) async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    final state = AppState.test(
      driftCategoryRepository: DriftCategoryRepository(db),
      driftExpenseRepository: DriftExpenseRepository(db),
      driftBudgetRepository: DriftBudgetRepository(db),
      driftAccountRepository: DriftAccountRepository(db),
      driftIncomeRepository: DriftIncomeRepository(db),
      settingsService: _Settings(),
      settings: WalletMeltSettings.defaults
          .copyWith(hasCompletedOnboarding: true, currency: 'PKR'),
    );
    late Account account;
    await tester.runAsync(() async {
      final now = DateTime.now();
      account = await state.createAccount(
        name: 'Bank',
        type: AccountType.bank,
        currency: 'PKR',
        openingBalanceMinorUnits: 100000,
        openingDate: DateTime(now.year - 1, now.month, now.day),
      );
      await state.createIncomeSchedule(
        title: 'Salary',
        source: IncomeSource.salary,
        amountMinorUnits: 5000000,
        cycle: 'monthly',
        firstDueDate: DateTime(now.year, now.month, now.day - 1),
        accountId: account.id,
      );
    });
    return (state, account);
  }

  testWidgets('due income prompts, confirm updates balance and clears prompt',
      (tester) async {
    final (state, _) = await setUp(tester);
    await tester.pumpWidget(harness(state));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_due_income')), findsOneWidget);
    expect(find.text('Did Salary arrive?'), findsOneWidget);

    await tester.tap(find.text('Received'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '48000');
    await tester.tap(find.text('Confirm received'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_due_income')), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('dashboard_balance')),
            matching: find.textContaining('49,000')),
        findsOneWidget);
  });

  testWidgets('skip clears the prompt without changing the balance',
      (tester) async {
    final (state, account) = await setUp(tester);
    await tester.pumpWidget(harness(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_due_income')), findsNothing);
    expect(
        state.accountBalances
            .firstWhere((b) => b.account.id == account.id)
            .balanceMinorUnits,
        100000);
    expect(state.incomes, isEmpty);
  });

  testWidgets('suggested budget reflects expected income', (tester) async {
    final (state, _) = await setUp(tester);
    await tester.pumpWidget(harness(state));
    await tester.pumpAndSettle();
    // Overdue unconfirmed Salary still counts toward the month it falls in.
    expect(state.expectedIncomeThisMonthMinorUnits, greaterThanOrEqualTo(5000000));
    expect(state.suggestedMonthlyBudget, isNotNull);
  });
}
