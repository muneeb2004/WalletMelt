import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_debt_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_subscription_repository.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/debt.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/types/subscription.dart';

class _Settings extends SettingsService {
  @override
  Future<WalletMeltSettings> load() async => WalletMeltSettings.defaults;
  @override
  Future<void> save(WalletMeltSettings settings) async {}
}

void main() {
  late WalletMeltDatabase db;
  late DriftAccountRepository accounts;
  late DriftDebtRepository debts;

  setUp(() {
    db = WalletMeltDatabase(NativeDatabase.memory());
    accounts = DriftAccountRepository(db);
    debts = DriftDebtRepository(db);
  });
  tearDown(() => db.close());

  Future<Account> bank({String currency = 'PKR', int opening = 1000000}) =>
      accounts.create(
        name: 'Bank',
        type: AccountType.bank,
        currency: currency,
        openingBalanceMinorUnits: opening,
        openingDate: DateTime(2026, 1, 1),
      );

  DebtRecord debt(String id, DebtType type, double amount,
          {String? accountId, String currency = 'PKR'}) =>
      DebtRecord(
        id: id,
        personName: 'Ali',
        type: type,
        principalAmount: amount,
        remainingAmount: amount,
        currency: currency,
        createdAt: DateTime(2026, 6, 1).toIso8601String(),
        status: DebtStatus.active,
        accountId: accountId,
      );

  Future<void> repay(String debtId, double amount, {String id = 'r1'}) =>
      debts.addRepayment(DebtRepayment(
        id: id,
        debtId: debtId,
        amount: amount,
        createdAt: DateTime(2026, 6, 10).toIso8601String(),
      ));

  group('debts move linked account balances', () {
    test('loan given: principal out, repayments in', () async {
      final a = await bank();
      await debts.createDebt(debt('d1', DebtType.loanGiven, 500, accountId: a.id));
      expect(await accounts.balanceOf(a.id), 1000000 - 50000);
      await repay('d1', 200);
      expect(await accounts.balanceOf(a.id), 1000000 - 50000 + 20000);
    });

    test('loan taken: principal in, repayments out', () async {
      final a = await bank();
      await debts.createDebt(debt('d1', DebtType.loanTaken, 500, accountId: a.id));
      expect(await accounts.balanceOf(a.id), 1000000 + 50000);
      await repay('d1', 125.5);
      expect(await accounts.balanceOf(a.id), 1000000 + 50000 - 12550);
    });

    test('owedToMe and iOwe have no principal movement, only repayments',
        () async {
      final a = await bank();
      await debts.createDebt(debt('d1', DebtType.owedToMe, 300, accountId: a.id));
      await debts.createDebt(debt('d2', DebtType.iOwe, 400, accountId: a.id));
      expect(await accounts.balanceOf(a.id), 1000000);
      await repay('d1', 100, id: 'r1'); // they pay me
      await repay('d2', 150, id: 'r2'); // I pay them
      expect(await accounts.balanceOf(a.id), 1000000 + 10000 - 15000);
    });

    test('unlinked, foreign-currency and pre-opening debts do nothing',
        () async {
      final a = await bank();
      await debts.createDebt(debt('d1', DebtType.loanGiven, 500));
      await debts.createDebt(
          debt('d2', DebtType.loanGiven, 500, accountId: a.id, currency: 'USD'));
      final early = debt('d3', DebtType.loanGiven, 500, accountId: a.id)
          .copyWith(createdAt: DateTime(2025, 12, 31).toIso8601String());
      await debts.createDebt(early);
      expect(await accounts.balanceOf(a.id), 1000000);
    });

    test('deleting a debt reverts its balance effect and linked accounts are archived',
        () async {
      final a = await bank();
      await debts.createDebt(debt('d1', DebtType.loanGiven, 500, accountId: a.id));
      expect(await accounts.deleteOrArchive(a.id), isFalse);
      await debts.deleteDebt('d1');
      expect(await accounts.balanceOf(a.id), 1000000);
    });
  });

  group('subscription renewals', () {
    Future<(AppState, Account)> setup({
      String subCurrency = 'PKR',
      bool archive = false,
      String accountCurrency = 'PKR',
    }) async {
      final a = await bank(currency: accountCurrency);
      if (archive) await accounts.setArchived(a.id, true);
      final subs = DriftSubscriptionRepository(db);
      await subs.create(Subscription(
        id: 's1',
        name: 'Netflix',
        categoryId: 'grocery',
        amount: 1000,
        currency: subCurrency,
        startDate: '2026-06-01',
        nextOccurrenceDate: '2026-06-01',
        billingCycle: 'monthly',
        status: SubscriptionStatus.active,
        createdAt: 't',
        updatedAt: 't',
        accountId: a.id,
      ));
      final state = AppState.test(
        driftCategoryRepository: DriftCategoryRepository(db),
        driftExpenseRepository: DriftExpenseRepository(db),
        driftBudgetRepository: DriftBudgetRepository(db),
        driftSubscriptionRepository: subs,
        driftAccountRepository: accounts,
        settingsService: _Settings(),
        settings: WalletMeltSettings.defaults
            .copyWith(hasCompletedOnboarding: true, currency: subCurrency),
      );
      await state.refresh();
      return (state, a);
    }

    test('renewals reduce the linked account balance', () async {
      final (state, a) = await setup();
      final renewals = state.expenses.where((e) => e.title.contains('Netflix'));
      expect(renewals, isNotEmpty);
      expect(renewals.every((e) => e.accountId == a.id), isTrue);
      final spent = renewals.fold<double>(0, (s, e) => s + e.amount);
      expect(await accounts.balanceOf(a.id), 1000000 - (spent * 100).round());
    });

    test('archived account leaves renewals unassigned', () async {
      final (state, a) = await setup(archive: true);
      final renewals = state.expenses.where((e) => e.title.contains('Netflix'));
      expect(renewals, isNotEmpty);
      expect(renewals.every((e) => e.accountId == null), isTrue);
      expect(await accounts.balanceOf(a.id), 1000000);
    });

    test('currency mismatch leaves renewals unassigned', () async {
      final (state, _) = await setup(subCurrency: 'USD', accountCurrency: 'PKR');
      final renewals = state.expenses.where((e) => e.title.contains('Netflix'));
      expect(renewals, isNotEmpty);
      expect(renewals.every((e) => e.accountId == null), isTrue);
    });

    test('editing a subscription keeps its account', () async {
      final (state, a) = await setup();
      final sub = state.subscriptions.single;
      expect(sub.accountId, a.id);
      await state.updateSubscription(sub.copyWith(name: 'Netflix 4K'));
      expect(state.subscriptions.single.accountId, a.id);
    });
  });
}
