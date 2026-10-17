import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_income_repository.dart';
import 'package:wallet_melt/src/screens/accounts/accounts_screen.dart';
import 'package:wallet_melt/src/screens/income/income_screen.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/income.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/widgets/primary_button.dart';

class _Settings extends SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}

void main() {
  Future<AppState> makeState(WidgetTester tester) async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    final state = AppState.test(
      driftAccountRepository: DriftAccountRepository(db),
      driftIncomeRepository: DriftIncomeRepository(db),
      settingsService: _Settings(),
      settings: WalletMeltSettings.defaults
          .copyWith(hasCompletedOnboarding: true, currency: 'PKR'),
    );
    await tester.runAsync(() async {
      await state.createAccount(
        name: 'Bank',
        type: AccountType.bank,
        currency: 'PKR',
        openingBalanceMinorUnits: 100000,
      );
      await state.createAccount(
        name: 'Wallet',
        type: AccountType.wallet,
        currency: 'PKR',
      );
    });
    return state;
  }

  Widget host(AppState state, Widget screen) => ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(theme: WalletMeltTheme.light(), home: screen),
      );

  testWidgets('accounts screen lists balances and opens detail and transfer',
      (tester) async {
    final state = await makeState(tester);
    await tester.pumpWidget(host(state, const AccountsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Bank'), findsWidgets);
    expect(find.text('Wallet'), findsWidgets);
    expect(find.text('Total balance'), findsOneWidget);

    await tester.tap(find.text('Bank').first);
    await tester.pumpAndSettle();
    expect(find.text('Update balance'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '250');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Transfer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        state.accountBalances
            .firstWhere((b) => b.account.name == 'Wallet')
            .balanceMinorUnits,
        25000);
  });

  testWidgets('income screen adds a one-off income that raises the balance',
      (tester) async {
    final state = await makeState(tester);
    await tester.pumpWidget(host(state, const IncomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Record money coming in'), findsOneWidget);

    await tester.tap(find.text('Add income'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Pocket money');
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '2000');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Add income'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(state.incomes.single.title, 'Pocket money');
    expect(find.text('Pocket money'), findsOneWidget);
  });

  testWidgets('income screen creates a repeating schedule', (tester) async {
    final state = await makeState(tester);
    await tester.pumpWidget(host(state, const IncomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add income'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Salary');
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '50000');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Add repeating income'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(state.incomeSchedules.single.cycle, 'monthly');
    expect(find.text('Repeating'), findsOneWidget);
    expect(state.incomeSchedules.single.status, IncomeScheduleStatus.active);
  });
}
