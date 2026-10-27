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
    expect(find.text('Add money'), findsOneWidget);
    expect(find.text('Spend money'), findsOneWidget);
    expect(find.text('Update balance'), findsNothing);
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

  testWidgets('add money and spend money change the balance and are deletable',
      (tester) async {
    final state = await makeState(tester);
    await tester.pumpWidget(host(state, const AccountsScreen()));
    await tester.pumpAndSettle();
    int bank() => state.accountBalances
        .firstWhere((b) => b.account.name == 'Bank')
        .balanceMinorUnits;

    await tester.tap(find.text('Bank').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add money'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '500');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Add money'));
    await tester.pumpAndSettle();
    expect(bank(), 150000);
    expect(find.text('Money added'), findsOneWidget);

    await tester.tap(find.text('Spend money'));
    await tester.pumpAndSettle();
    expect(find.textContaining('add it as an expense'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '200');
    await tester.enterText(
        find.widgetWithText(TextField, 'Note (optional)'), 'ATM fee');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Spend money'));
    await tester.pumpAndSettle();
    expect(bank(), 130000);
    expect(find.text('ATM fee'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(bank(), 150000);
  });

  testWidgets('account sheet shows Correct balance up front and previews the change',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final state = await makeState(tester);
    await tester.pumpWidget(host(state, const AccountsScreen()));
    await tester.pumpAndSettle();
    int bank() => state.accountBalances
        .firstWhere((b) => b.account.name == 'Bank')
        .balanceMinorUnits;

    await tester.tap(find.text('Bank').first);
    await tester.pumpAndSettle();
    // The two main actions share one row at equal width on a narrow phone.
    expect(tester.getSize(find.widgetWithText(FilledButton, 'Add money')).width,
        tester.getSize(find.widgetWithText(OutlinedButton, 'Spend money')).width);
    expect(tester.takeException(), isNull);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Correct balance'), findsOneWidget);
    expect(find.text('Match what you really hold'), findsOneWidget);
    expect(find.text('Edit account'), findsOneWidget);

    await tester.tap(find.text('Correct balance'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Actual balance'), '1100');
    await tester.pumpAndSettle();
    expect(find.text('Change'), findsOneWidget);
    expect(find.textContaining('+'), findsWidgets);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(bank(), 110000);
  });

  testWidgets('add account needs only a name and keeps options collapsed',
      (tester) async {
    final state = await makeState(tester);
    await tester.pumpWidget(host(state, const AccountsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    expect(find.text('Starting balance'), findsOneWidget);
    expect(find.text('Card'), findsNothing);
    expect(find.text('Other'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Savings');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Add account'));
    await tester.pumpAndSettle();

    final saved =
        state.accountBalances.firstWhere((b) => b.account.name == 'Savings');
    expect(saved.balanceMinorUnits, 0);
    expect(saved.account.type, AccountType.cash);
    expect(saved.account.currency, 'PKR');
    expect(saved.account.includeInTotal, isTrue);
  });

  test('unknown stored account types fall back to cash', () {
    expect(accountTypeFromName('card'), AccountType.cash);
    expect(accountTypeFromName(null), AccountType.cash);
    expect(accountTypeFromName('wallet'), AccountType.wallet);
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
