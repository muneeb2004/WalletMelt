import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/screens/subscription/subscription_form_sheet.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/types/subscription.dart';

class _Settings extends SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}

Subscription _sub(String cycle, {int? offset, String? accountId}) => Subscription(
      id: 's',
      name: 'Gym',
      categoryId: 'c',
      amount: 100,
      currency: 'PKR',
      startDate: '2030-01-31',
      nextOccurrenceDate: '2030-01-31',
      billingCycle: cycle,
      status: SubscriptionStatus.active,
      createdAt: '2026-01-01T00:00:00.000',
      updatedAt: '2026-01-01T00:00:00.000',
      notificationOffset: offset,
      accountId: accountId,
    );

void main() {
  testWidgets('edit sheet opens for awkward stored data without throwing',
      (tester) async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    final state = AppState.test(
      driftAccountRepository: DriftAccountRepository(db),
      settingsService: _Settings(),
      settings: WalletMeltSettings.defaults
          .copyWith(hasCompletedOnboarding: true, currency: 'PKR'),
    );
    late Account account;
    await tester.runAsync(() async {
      account = await state.createAccount(
        name: 'Old bank',
        type: AccountType.bank,
        currency: 'PKR',
        openingBalanceMinorUnits: 1000,
      );
    });

    for (final sub in [
      _sub('weekly', offset: 5),
      _sub('custom_45', accountId: 'gone-account'),
      _sub('Semi-Annual', accountId: account.id),
      _sub('yearly'),
    ]) {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: WalletMeltTheme.light(),
          home: Scaffold(body: SubscriptionFormSheet(existing: sub)),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: sub.billingCycle);
      expect(find.text('Edit subscription'), findsOneWidget);
      expect(find.text('Next renewal'), findsOneWidget);
    }
  });
}
