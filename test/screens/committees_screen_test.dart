import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/components/account/due_committee_card.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_committee_repository.dart';
import 'package:wallet_melt/src/screens/committees/committees_screen.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/committee.dart';
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
      driftCommitteeRepository: DriftCommitteeRepository(db),
      settingsService: _Settings(),
      settings: WalletMeltSettings.defaults
          .copyWith(hasCompletedOnboarding: true, currency: 'PKR'),
    );
    await tester.runAsync(() async {
      await state.createAccount(
        name: 'Bank',
        type: AccountType.bank,
        currency: 'PKR',
        openingBalanceMinorUnits: 5000000,
        openingDate: DateTime(2020, 1, 1),
      );
    });
    return state;
  }

  Widget host(AppState state, Widget screen) => ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(theme: WalletMeltTheme.light(), home: screen),
      );

  testWidgets('add a committee, mark a month paid and confirm the payout',
      (tester) async {
    final state = await makeState(tester);
    await tester.pumpWidget(host(state, const CommitteesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Track your committee'), findsOneWidget);

    await tester.tap(find.text('Add committee'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Office BC');
    await tester.enterText(
        find.widgetWithText(TextField, 'Your monthly installment'), '10000');
    await tester.enterText(find.widgetWithText(TextField, 'Number of members'), '3');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Add committee'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Add committee'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final c = state.committeeProgress.single.committee;
    expect(c.memberCount, 3);
    expect(c.payoutMinorUnits, 3000000, reason: '10,000 x 3 members');
    expect(find.text('Office BC'), findsOneWidget);
    expect(find.textContaining('Paid 0 of 3'), findsOneWidget);

    await tester.tap(find.text('Office BC'));
    await tester.pumpAndSettle();
    expect(find.text('Month 1 · your payout'), findsOneWidget);
    await tester.tap(find.text('Mark paid').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(state.committeeProgress.single.paidCount, 1);

    await tester.tap(find.text('Received'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Confirm received'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(state.committeeProgress.single.payoutReceived, isTrue);
  });

  testWidgets('dashboard prompt: confirm moves the balance, Later hides it',
      (tester) async {
    final state = await makeState(tester);
    late Committee committee;
    await tester.runAsync(() async {
      final now = DateTime.now();
      committee = await state.createCommittee(
        name: 'Family BC',
        monthlyMinorUnits: 1000000,
        memberCount: 6,
        payoutMonth: 4,
        startDate: DateTime(now.year, now.month, now.day - 1),
        accountId: state.accounts.single.id,
      );
    });
    Widget card() => host(state, Scaffold(body: DueCommitteeCard(state: state)));

    await tester.pumpWidget(card());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard_due_committee')), findsOneWidget);
    expect(find.text('Did you pay your Family BC installment?'), findsOneWidget);

    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '9500');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Confirm paid'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(state.committeeProgress.single.paidMinorUnits, 950000);
    expect(state.accountBalances.single.balanceMinorUnits, 5000000 - 950000);
    expect(find.byKey(const Key('dashboard_due_committee')), findsNothing);
    expect(committee.id, isNotEmpty);

    // A second due item can be dismissed with Later without recording anything.
    await tester.runAsync(() async {
      final now = DateTime.now();
      await state.createCommittee(
        name: 'Friends BC',
        monthlyMinorUnits: 500000,
        memberCount: 4,
        payoutMonth: 4,
        startDate: DateTime(now.year, now.month, now.day - 1),
      );
    });
    await tester.pumpWidget(card());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard_due_committee')), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard_due_committee')), findsNothing);
    expect(state.committeeProgress.length, 2);
    expect(
        state.committeeProgress
            .firstWhere((p) => p.committee.name == 'Friends BC')
            .paidCount,
        0);
  });
}
