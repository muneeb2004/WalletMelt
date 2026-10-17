import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/components/account/account_picker_field.dart';
import 'package:wallet_melt/src/types/account.dart';

Account _account(String id, String name, String currency,
        {bool archived = false}) =>
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

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));

void main() {
  final accounts = [
    _account('a', 'Bank PKR', 'PKR'),
    _account('b', 'Wallet USD', 'USD'),
    _account('c', 'Old PKR', 'PKR', archived: true),
  ];

  testWidgets('offers only same-currency, non-archived accounts',
      (tester) async {
    String? picked = 'unset';
    await tester.pumpWidget(_host(AccountPickerField(
      accounts: accounts,
      currency: 'PKR',
      value: null,
      onChanged: (v) => picked = v,
    )));
    await tester.tap(find.byKey(const ValueKey('expense-account-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Bank PKR'), findsOneWidget);
    expect(find.text('Wallet USD'), findsNothing);
    expect(find.text('Old PKR'), findsNothing);
    await tester.tap(find.text('Bank PKR').last);
    await tester.pumpAndSettle();
    expect(picked, 'a');
  });

  testWidgets('keeps an archived account visible when it is the current value',
      (tester) async {
    await tester.pumpWidget(_host(AccountPickerField(
      accounts: accounts,
      currency: 'PKR',
      value: 'c',
      onChanged: (_) {},
    )));
    expect(find.text('Old PKR'), findsOneWidget);
  });

  testWidgets('renders nothing when no account matches the currency',
      (tester) async {
    await tester.pumpWidget(_host(AccountPickerField(
      accounts: accounts,
      currency: 'EUR',
      value: null,
      onChanged: (_) {},
    )));
    expect(find.byKey(const ValueKey('expense-account-picker')), findsNothing);
  });
}
