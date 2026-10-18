import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/components/account/choose_account_sheet.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_debt_repository.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/debt.dart';

Account _acc(String id, String name, String currency, {bool archived = false}) =>
    Account(
      id: id,
      name: name,
      type: AccountType.bank,
      currency: currency,
      openingBalanceMinorUnits: 0,
      openingDate: '2026-01-01T00:00:00.000',
      createdAt: 't',
      updatedAt: 't',
      isArchived: archived,
    );

void main() {
  group('DriftDebtRepository.setAccount', () {
    late WalletMeltDatabase db;
    late DriftDebtRepository debts;
    late DriftAccountRepository accounts;

    setUp(() {
      db = WalletMeltDatabase(NativeDatabase.memory());
      debts = DriftDebtRepository(db);
      accounts = DriftAccountRepository(db);
    });
    tearDown(() => db.close());

    Future<void> makeDebt() => debts.createDebt(DebtRecord(
          id: 'd1',
          personName: 'Ali',
          type: DebtType.loanGiven,
          principalAmount: 500,
          remainingAmount: 500,
          currency: 'PKR',
          createdAt: DateTime(2026, 6, 1).toIso8601String(),
          status: DebtStatus.active,
        ));

    Future<Account> bank({String currency = 'PKR'}) => accounts.create(
          name: 'Bank',
          type: AccountType.bank,
          currency: currency,
          openingBalanceMinorUnits: 1000000,
          openingDate: DateTime(2026, 1, 1),
        );

    test('linking applies the debt to the balance and clearing reverts it',
        () async {
      final a = await bank();
      await makeDebt();
      expect(await accounts.balanceOf(a.id), 1000000);

      await debts.setAccount('d1', a.id);
      expect((await debts.getById('d1'))?.accountId, a.id);
      expect(await accounts.balanceOf(a.id), 1000000 - 50000);

      await debts.setAccount('d1', null);
      expect((await debts.getById('d1'))?.accountId, isNull);
      expect(await accounts.balanceOf(a.id), 1000000);
    });

    test('rejects wrong currency, archived and missing accounts', () async {
      final usd = await bank(currency: 'USD');
      final archived = await bank();
      await accounts.setArchived(archived.id, true);
      await makeDebt();
      expect(() => debts.setAccount('d1', usd.id), throwsArgumentError);
      expect(() => debts.setAccount('d1', archived.id), throwsStateError);
      expect(() => debts.setAccount('d1', 'nope'), throwsStateError);
      expect(() => debts.setAccount('missing', null), returnsNormally);
    });
  });

  group('showChooseAccountSheet', () {
    Widget host(void Function(BuildContext) open) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => open(context),
                child: const Text('open'),
              ),
            ),
          ),
        );

    testWidgets('offers same-currency accounts and returns the choice',
        (tester) async {
      String? chosen = 'unset';
      await tester.pumpWidget(host((context) => showChooseAccountSheet(
            context,
            accounts: [
              _acc('a', 'Bank PKR', 'PKR'),
              _acc('b', 'Wallet USD', 'USD'),
              _acc('c', 'Old PKR', 'PKR', archived: true),
            ],
            currency: 'PKR',
            currentAccountId: null,
            title: 'Pick',
            explanation: 'why',
            onSelected: (id) async => chosen = id,
          )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Bank PKR'), findsOneWidget);
      expect(find.text('Wallet USD'), findsNothing);
      expect(find.text('Old PKR'), findsNothing);
      await tester.tap(find.text('Bank PKR'));
      await tester.pumpAndSettle();
      expect(chosen, 'a');
      expect(find.text('Pick'), findsNothing, reason: 'sheet closes');
    });

    testWidgets('clearing the link passes null and keeps an archived current',
        (tester) async {
      String? chosen = 'unset';
      await tester.pumpWidget(host((context) => showChooseAccountSheet(
            context,
            accounts: [_acc('c', 'Old PKR', 'PKR', archived: true)],
            currency: 'PKR',
            currentAccountId: 'c',
            title: 'Pick',
            explanation: 'why',
            onSelected: (id) async => chosen = id,
          )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Old PKR'), findsOneWidget);
      await tester.tap(find.text('No account'));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
    });
  });
}
