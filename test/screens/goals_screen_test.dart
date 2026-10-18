import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/components/account/dashboard_balance_card.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_goal_repository.dart';
import 'package:wallet_melt/src/screens/goals/goals_screen.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/savings_goal.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/widgets/primary_button.dart';

class _Settings extends SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}

void main() {
  Future<AppState> makeState(WidgetTester tester, {bool withAccount = true}) async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    final state = AppState.test(
      driftAccountRepository: DriftAccountRepository(db),
      driftGoalRepository: DriftGoalRepository(db),
      settingsService: _Settings(),
      settings: WalletMeltSettings.defaults
          .copyWith(hasCompletedOnboarding: true, currency: 'PKR'),
    );
    if (withAccount) {
      await tester.runAsync(() async {
        await state.createAccount(
          name: 'Bank',
          type: AccountType.bank,
          currency: 'PKR',
          openingBalanceMinorUnits: 1000000,
        );
      });
    }
    return state;
  }

  Widget host(AppState state, Widget screen) => ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(theme: WalletMeltTheme.light(), home: screen),
      );

  testWidgets('asks for an account first, then shows the empty goals state',
      (tester) async {
    final noAccount = await makeState(tester, withAccount: false);
    await tester.pumpWidget(host(noAccount, const GoalsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Add an account first'), findsOneWidget);
    expect(find.text('Add goal'), findsNothing);

    final withAccount = await makeState(tester);
    await tester.pumpWidget(host(withAccount, const GoalsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Save toward something'), findsOneWidget);
    expect(find.text('Add goal'), findsOneWidget);
  });

  testWidgets('add a goal, set money aside, see free to spend, mark achieved',
      (tester) async {
    final state = await makeState(tester);
    await tester.pumpWidget(host(state, const GoalsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add goal'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'What are you saving for?'), 'Laptop');
    await tester.enterText(find.widgetWithText(TextField, 'Target amount'), '3000');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Add goal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(state.goalProgress.single.goal.name, 'Laptop');
    expect(find.text('Laptop'), findsOneWidget);

    await tester.tap(find.text('Laptop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set aside'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '1200');
    await tester.tap(find.widgetWithText(FilledButton, 'Set aside').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(state.goalProgress.single.savedMinorUnits, 120000);
    expect(state.reservedByAccount.values.single, 120000);
    final account = state.accountBalances.single;
    expect(account.balanceMinorUnits, 1000000, reason: 'balance unchanged');
    expect(state.freeToSpendFor(account.account.id), 880000);

    await tester.tap(find.text('Mark achieved'));
    await tester.pumpAndSettle();
    expect(state.goalProgress.single.goal.status, GoalStatus.achieved);
    expect(state.reservedByAccount, isEmpty);
    expect(state.freeToSpendFor(account.account.id), 1000000);
  });

  testWidgets('dashboard card shows free to spend only while money is set aside',
      (tester) async {
    final state = await makeState(tester);
    late SavingsGoal goal;
    await tester.runAsync(() async {
      goal = await state.createGoal(
        name: 'Fees',
        targetMinorUnits: 500000,
        accountId: state.accountBalances.single.account.id,
      );
    });
    await tester.pumpWidget(
        host(state, Scaffold(body: DashboardBalanceCard(state: state))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard_free_to_spend')), findsNothing);

    await tester.runAsync(() => state.setAsideForGoal(goal.id, 200000));
    await tester.pumpWidget(
        host(state, Scaffold(body: DashboardBalanceCard(state: state))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard_free_to_spend')), findsOneWidget);
    expect(find.textContaining('Free to spend'), findsOneWidget);
    expect(find.textContaining('8,000'), findsWidgets);
  });
}
