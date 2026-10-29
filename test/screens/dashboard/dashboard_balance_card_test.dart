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
import 'package:wallet_melt/src/screens/dashboard/dashboard_screen.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/settings.dart';

class _Settings extends SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}

void main() {
  Widget harness(AppState state) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        GoRoute(
            path: '/accounts',
            builder: (_, __) => const Scaffold(body: Text('Accounts mock'))),
      ],
    );
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp.router(
        theme: WalletMeltTheme.light(),
        routerConfig: router,
      ),
    );
  }

  testWidgets(
      'balance card prompts, then follows account, expense and delete changes',
      (tester) async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    final state = AppState.test(
      driftCategoryRepository: DriftCategoryRepository(db),
      driftExpenseRepository: DriftExpenseRepository(db),
      driftBudgetRepository: DriftBudgetRepository(db),
      driftAccountRepository: DriftAccountRepository(db),
      settingsService: _Settings(),
      settings: WalletMeltSettings.defaults
          .copyWith(hasCompletedOnboarding: true, currency: 'PKR'),
    );
    await tester.runAsync(state.refresh);

    await tester.pumpWidget(harness(state));
    await tester.pumpAndSettle();

    // No accounts yet: setup prompt, no balance.
    expect(find.byKey(const Key('dashboard_balance_prompt')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_balance')), findsNothing);

    // Create an account holding 1,000.
    late Account account;
    await tester.runAsync(() async {
      account = await state.createAccount(
        name: 'Bank',
        type: AccountType.bank,
        currency: 'PKR',
        openingBalanceMinorUnits: 100000,
      );
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard_balance')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_balance_prompt')), findsNothing);
    expect(find.textContaining('1,000'), findsWidgets);
    // The balance sits beside the spend tile and says it can be opened.
    expect(find.byKey(const Key('dashboard_hero')), findsOneWidget);
    expect(find.descendant(
            of: find.byKey(const Key('dashboard_balance')),
            matching: find.text('1 account')),
        findsOneWidget);
    expect(find.descendant(
            of: find.byKey(const Key('dashboard_balance')),
            matching: find.byIcon(Icons.chevron_right_rounded)),
        findsOneWidget);
    expect(
        tester.getTopLeft(find.byKey(const Key('dashboard_balance'))).dy,
        tester.getTopLeft(find.byKey(const Key('dashboard_hero'))).dy);

    // Spend 250 from it via AppState: the card must update without a rebuild
    // of the screen (no stale Riverpod copy).
    late Expense expense;
    await tester.runAsync(() async {
      final now = DateTime.now();
      expense = await state.addExpense(ExpenseDraft(
        amount: 250,
        currency: 'PKR',
        categoryId: 'grocery',
        title: 'Milk',
        date: DateTime(now.year, now.month, now.day),
        accountId: account.id,
      ));
    });
    await tester.pumpAndSettle();
    expect(find.descendant(
            of: find.byKey(const Key('dashboard_balance')),
            matching: find.textContaining('750')),
        findsOneWidget);

    // Soft delete restores the balance.
    await tester.runAsync(() => state.softDeleteExpense(expense.id));
    await tester.pumpAndSettle();
    expect(find.descendant(
            of: find.byKey(const Key('dashboard_balance')),
            matching: find.textContaining('1,000')),
        findsOneWidget);

    // Hide toggle masks the amount.
    await tester.tap(find.byTooltip('Hide balance'));
    await tester.pumpAndSettle();
    expect(find.text('••••'), findsOneWidget);
    expect(state.settings.hideBalance, isTrue);
  });

  testWidgets('no balance UI when accounts are unavailable', (tester) async {
    final state = AppState.test(
      settingsService: _Settings(),
      settings: WalletMeltSettings.defaults
          .copyWith(hasCompletedOnboarding: true, currency: 'PKR'),
    );
    expect(state.accountsAvailable, isFalse);
    await tester.pumpWidget(harness(state));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard_balance_prompt')), findsNothing);
    expect(find.byKey(const Key('dashboard_balance')), findsNothing);
  });
}
