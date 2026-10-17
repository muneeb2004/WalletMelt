import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/income_planner.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_income_repository.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/essential_expense.dart';
import 'package:wallet_melt/src/types/income.dart';
import 'package:wallet_melt/src/types/subscription.dart';
import 'package:wallet_melt/src/utils/recurrence.dart';

Subscription _sub(String cycle, double amount, {bool active = true}) =>
    Subscription(
      id: cycle,
      name: cycle,
      categoryId: 'grocery',
      amount: amount,
      currency: 'PKR',
      startDate: '2026-01-01',
      nextOccurrenceDate: '2026-07-01',
      billingCycle: cycle,
      status: active ? SubscriptionStatus.active : SubscriptionStatus.paused,
      createdAt: 't',
      updatedAt: 't',
    );

EssentialExpenseTemplate _essential(String freq, double amount) =>
    EssentialExpenseTemplate(
      id: freq,
      name: freq,
      categoryId: 'rent',
      frequency: freq,
      expectedAmount: amount,
      isActive: true,
      isFuel: false,
      createdAt: 't',
      updatedAt: 't',
    );

void main() {
  late WalletMeltDatabase db;
  late DriftIncomeRepository incomes;
  late DriftAccountRepository accounts;

  setUp(() {
    db = WalletMeltDatabase(NativeDatabase.memory());
    incomes = DriftIncomeRepository(db);
    accounts = DriftAccountRepository(db);
  });
  tearDown(() => db.close());

  Future<Account> bank(
          {String currency = 'PKR', int opening = 0, DateTime? opened}) =>
      accounts.create(
        name: 'Bank',
        type: AccountType.bank,
        currency: currency,
        openingBalanceMinorUnits: opening,
        openingDate: opened ?? DateTime(2026, 6, 1),
      );

  group('recurrence', () {
    test('month-end anchoring and weekly', () {
      expect(advanceByCycle('monthly', DateTime(2026, 1, 31), 31),
          DateTime(2026, 2, 28));
      expect(advanceByCycle('monthly', DateTime(2026, 2, 28), 31),
          DateTime(2026, 3, 31));
      expect(advanceByCycle('weekly', DateTime(2026, 6, 1), 1),
          DateTime(2026, 6, 8));
      expect(advanceByCycle('custom_0', DateTime(2026, 6, 1), 1),
          DateTime(2026, 7, 1));
    });
  });

  group('balance', () {
    test('income raises the linked account balance and soft delete reverts it',
        () async {
      final a = await bank(opening: 10000);
      final income = await incomes.addIncome(
        title: 'Salary',
        source: IncomeSource.salary,
        amountMinorUnits: 5000000,
        currency: 'PKR',
        date: DateTime(2026, 6, 25),
        accountId: a.id,
      );
      expect(await accounts.balanceOf(a.id), 5010000);
      await incomes.softDeleteIncome(income.id);
      expect(await accounts.balanceOf(a.id), 10000);
    });

    test('income without an account changes no balance; wrong currency rejected',
        () async {
      final a = await bank(opening: 100);
      await incomes.addIncome(
        title: 'Gift',
        source: IncomeSource.gift,
        amountMinorUnits: 999,
        currency: 'PKR',
        date: DateTime(2026, 6, 25),
      );
      expect(await accounts.balanceOf(a.id), 100);
      expect(
        () => incomes.addIncome(
          title: 'x',
          source: IncomeSource.other,
          amountMinorUnits: 1,
          currency: 'USD',
          date: DateTime(2026, 6, 25),
          accountId: a.id,
        ),
        throwsArgumentError,
      );
      expect(
        () => incomes.addIncome(
          title: 'x',
          source: IncomeSource.other,
          amountMinorUnits: 0,
          currency: 'PKR',
          date: DateTime(2026, 6, 25),
        ),
        throwsArgumentError,
      );
    });

    test('account with only an income is archived, not deleted', () async {
      final a = await bank();
      await incomes.addIncome(
        title: 'Salary',
        source: IncomeSource.salary,
        amountMinorUnits: 100,
        currency: 'PKR',
        date: DateTime(2026, 6, 25),
        accountId: a.id,
      );
      expect(await accounts.deleteOrArchive(a.id), isFalse);
    });
  });

  group('schedules', () {
    test('confirm records income, advances, and keeps month-end anchor',
        () async {
      final a = await bank(opened: DateTime(2026, 1, 1));
      final s = await incomes.createSchedule(
        title: 'Salary',
        source: IncomeSource.salary,
        amountMinorUnits: 8000000,
        currency: 'PKR',
        cycle: 'monthly',
        firstDueDate: DateTime(2026, 1, 31),
        accountId: a.id,
      );
      expect((await incomes.listDue(DateTime(2026, 1, 30))), isEmpty);
      expect((await incomes.listDue(DateTime(2026, 1, 31))).length, 1);

      final got = await incomes.confirmReceived(s.id,
          amountMinorUnits: 7500000, receivedOn: DateTime(2026, 2, 1));
      expect(got.scheduleId, s.id);
      expect(got.amountMinorUnits, 7500000);
      final after = (await incomes.listSchedules()).single;
      expect(DateTime.parse(after.nextDueDate), DateTime(2026, 2, 28));
      expect(await accounts.balanceOf(a.id), 7500000);

      await incomes.skipOccurrence(s.id);
      final skipped = (await incomes.listSchedules()).single;
      expect(DateTime.parse(skipped.nextDueDate), DateTime(2026, 3, 31));
      expect((await incomes.listIncomes()).length, 1);
    });

    test('paused and deleted schedules are never due', () async {
      final s = await incomes.createSchedule(
        title: 'Allowance',
        source: IncomeSource.allowance,
        amountMinorUnits: 100,
        currency: 'PKR',
        cycle: 'weekly',
        firstDueDate: DateTime(2026, 6, 1),
      );
      await incomes.setScheduleStatus(s.id, IncomeScheduleStatus.paused);
      expect(await incomes.listDue(DateTime(2026, 7, 1)), isEmpty);
      await incomes.setScheduleStatus(s.id, IncomeScheduleStatus.active);
      expect((await incomes.listDue(DateTime(2026, 7, 1))).length, 1);
      await incomes.deleteSchedule(s.id);
      expect(await incomes.listDue(DateTime(2026, 7, 1)), isEmpty);
    });
  });

  group('IncomePlanner', () {
    IncomeSchedule schedule(String cycle, String next, int amount,
            {String currency = 'PKR', bool active = true}) =>
        IncomeSchedule(
          id: '$cycle$next',
          title: 't',
          source: IncomeSource.salary,
          amountMinorUnits: amount,
          currency: currency,
          cycle: cycle,
          startDate: next,
          nextDueDate: next,
          status: active
              ? IncomeScheduleStatus.active
              : IncomeScheduleStatus.paused,
          createdAt: 't',
          updatedAt: 't',
        );

    Income received(String date, int amount, {String currency = 'PKR'}) =>
        Income(
          id: date,
          title: 't',
          source: IncomeSource.other,
          amountMinorUnits: amount,
          currency: currency,
          date: date,
          createdAt: 't',
          updatedAt: 't',
        );

    test('counts received plus remaining and overdue occurrences', () {
      final total = IncomePlanner.expectedForMonth(
        month: DateTime(2026, 6, 15),
        currency: 'PKR',
        received: [
          received('2026-06-02T00:00:00.000', 1000),
          received('2026-05-30T00:00:00.000', 9999), // other month
          received('2026-06-03T00:00:00.000', 7, currency: 'USD'),
        ],
        schedules: [
          // weekly from Jun 10: 10, 17, 24 => 3 occurrences
          schedule('weekly', '2026-06-10T00:00:00.000', 100),
          // overdue monthly from May 28 still contributes its Jun 28 only
          schedule('monthly', '2026-05-28T00:00:00.000', 500),
          schedule('monthly', '2026-06-20T00:00:00.000', 500, active: false),
          schedule('monthly', '2026-06-20T00:00:00.000', 500, currency: 'USD'),
        ],
      );
      expect(total, 1000 + 300 + 500);
    });

    test('suggestion subtracts subscriptions and essentials, floors at zero',
        () {
      expect(
        IncomePlanner.suggestedBudget(
          expectedIncomeMinorUnits: 10000000,
          subscriptions: [_sub('monthly', 1000), _sub('annual', 12000), _sub('monthly', 5000, active: false)],
          essentials: [_essential('monthly', 20000), _essential('quarterly', 3000)],
        ),
        100000 - 1000 - 1000 - 20000 - 1000,
      );
      expect(
        IncomePlanner.suggestedBudget(
          expectedIncomeMinorUnits: 1000,
          subscriptions: [_sub('monthly', 5000)],
          essentials: const [],
        ),
        0,
      );
      expect(
        IncomePlanner.suggestedBudget(
          expectedIncomeMinorUnits: 0,
          subscriptions: const [],
          essentials: const [],
        ),
        isNull,
      );
    });
  });
}
