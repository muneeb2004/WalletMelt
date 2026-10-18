import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/goal_planner.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_goal_repository.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/savings_goal.dart';

GoalProgress _progress(String id, String accountId, int saved,
        {GoalStatus status = GoalStatus.active,
        int target = 100000,
        String? targetDate}) =>
    GoalProgress(
      goal: SavingsGoal(
        id: id,
        name: id,
        targetMinorUnits: target,
        currency: 'PKR',
        accountId: accountId,
        targetDate: targetDate,
        status: status,
        createdAt: 't',
        updatedAt: 't',
      ),
      savedMinorUnits: saved,
    );

Account _acc(String id, {bool include = true, bool archived = false}) => Account(
      id: id,
      name: id,
      type: AccountType.bank,
      currency: 'PKR',
      openingBalanceMinorUnits: 0,
      openingDate: '2026-01-01T00:00:00.000',
      createdAt: 't',
      updatedAt: 't',
      includeInTotal: include,
      isArchived: archived,
    );

void main() {
  group('GoalPlanner', () {
    test('reserved counts only active goals and floors at zero', () {
      final reserved = GoalPlanner.reservedByAccount([
        _progress('a', 'acc1', 30000),
        _progress('b', 'acc1', 20000),
        _progress('c', 'acc1', 99999, status: GoalStatus.achieved),
        _progress('d', 'acc2', 5000, status: GoalStatus.archived),
        _progress('e', 'acc3', -500),
      ]);
      expect(reserved, {'acc1': 50000, 'acc3': 0});
    });

    test('free to spend can go negative', () {
      expect(GoalPlanner.freeToSpend(100000, 30000), 70000);
      expect(GoalPlanner.freeToSpend(10000, 30000), -20000);
    });

    test('free totals follow the same inclusion rules as total balance', () {
      final totals = GoalPlanner.freeTotalsByCurrency([
        AccountBalance(account: _acc('a'), balanceMinorUnits: 100000),
        AccountBalance(account: _acc('b'), balanceMinorUnits: 50000),
        AccountBalance(account: _acc('c', include: false), balanceMinorUnits: 9999),
        AccountBalance(account: _acc('d', archived: true), balanceMinorUnits: 9999),
      ], {'a': 40000, 'c': 1});
      expect(totals.single.minorUnits, 60000 + 50000);
    });

    test('months left and monthly pace', () {
      final now = DateTime(2026, 6, 15);
      expect(GoalPlanner.monthsLeft(now, DateTime(2026, 6, 15)), 0);
      expect(GoalPlanner.monthsLeft(now, DateTime(2026, 6, 20)), 1);
      expect(GoalPlanner.monthsLeft(now, DateTime(2026, 9, 15)), 3);
      expect(GoalPlanner.monthsLeft(now, DateTime(2026, 9, 14)), 2);

      final p = _progress('g', 'a', 25000,
          target: 100000, targetDate: '2026-09-15T00:00:00.000');
      expect(GoalPlanner.monthlyPaceMinorUnits(progress: p, now: now), 25000);
      // Rounds up so the target is never missed by a minor unit.
      final q = _progress('g', 'a', 0,
          target: 100001, targetDate: '2026-09-15T00:00:00.000');
      expect(GoalPlanner.monthlyPaceMinorUnits(progress: q, now: now), 33334);
      expect(
          GoalPlanner.monthlyPaceMinorUnits(
              progress: _progress('g', 'a', 100000, targetDate: '2026-09-15'),
              now: now),
          isNull);
      expect(
          GoalPlanner.monthlyPaceMinorUnits(
              progress: _progress('g', 'a', 0), now: now),
          isNull);
    });

    test('progress fraction is clamped', () {
      expect(_progress('g', 'a', 150000).fraction, 1.0);
      expect(_progress('g', 'a', 25000).fraction, 0.25);
      expect(_progress('g', 'a', 150000).isReached, isTrue);
      expect(_progress('g', 'a', 25000).remainingMinorUnits, 75000);
    });
  });

  group('DriftGoalRepository', () {
    late WalletMeltDatabase db;
    late DriftGoalRepository goals;
    late DriftAccountRepository accounts;

    setUp(() {
      db = WalletMeltDatabase(NativeDatabase.memory());
      goals = DriftGoalRepository(db);
      accounts = DriftAccountRepository(db);
    });
    tearDown(() => db.close());

    Future<Account> bank({String currency = 'PKR'}) => accounts.create(
          name: 'Bank',
          type: AccountType.bank,
          currency: currency,
          openingBalanceMinorUnits: 500000,
          openingDate: DateTime(2026, 1, 1),
        );

    test('goal never changes the account balance; saved is derived', () async {
      final a = await bank();
      final g = await goals.createGoal(
          name: 'Laptop', targetMinorUnits: 300000, accountId: a.id);
      expect(g.currency, 'PKR');
      await goals.setAside(g.id, 100000);
      await goals.setAside(g.id, 50000);
      await goals.release(g.id, 30000);

      final progress = (await goals.listProgress()).single;
      expect(progress.savedMinorUnits, 120000);
      expect(await accounts.balanceOf(a.id), 500000);
      expect(GoalPlanner.reservedByAccount([progress])[a.id], 120000);
    });

    test('validations', () async {
      final a = await bank();
      final g = await goals.createGoal(
          name: 'Fees', targetMinorUnits: 100, accountId: a.id);
      expect(() => goals.createGoal(name: ' ', targetMinorUnits: 1, accountId: a.id),
          throwsArgumentError);
      expect(() => goals.createGoal(name: 'x', targetMinorUnits: 0, accountId: a.id),
          throwsArgumentError);
      expect(() => goals.createGoal(name: 'x', targetMinorUnits: 1, accountId: 'nope'),
          throwsStateError);
      expect(() => goals.setAside(g.id, 0), throwsArgumentError);
      await goals.setAside(g.id, 50);
      expect(() => goals.release(g.id, 51), throwsArgumentError);
      await accounts.setArchived(a.id, true);
      expect(() => goals.createGoal(name: 'y', targetMinorUnits: 1, accountId: a.id),
          throwsStateError);
    });

    test('mark achieved releases the reservation and keeps history',
        () async {
      final a = await bank();
      final g = await goals.createGoal(
          name: 'Trip', targetMinorUnits: 100000, accountId: a.id);
      await goals.setAside(g.id, 100000);
      await goals.markAchieved(g.id);

      final p = (await goals.listProgress()).single;
      expect(p.goal.status, GoalStatus.achieved);
      expect(p.savedMinorUnits, 0, reason: 'released');
      expect(GoalPlanner.reservedByAccount([p]), isEmpty);
      final history = await goals.listContributions(g.id);
      expect(history.map((c) => c.amountMinorUnits).toList()..sort(),
          [-100000, 100000]);
      expect(() => goals.setAside(g.id, 1), throwsStateError);

      await goals.reopen(g.id);
      await goals.setAside(g.id, 10);
      expect((await goals.listProgress()).single.savedMinorUnits, 10);
    });

    test('archived goals reserve nothing; deleted goals disappear', () async {
      final a = await bank();
      final g = await goals.createGoal(
          name: 'Gift', targetMinorUnits: 1000, accountId: a.id);
      await goals.setAside(g.id, 500);
      await goals.archive(g.id);
      expect(GoalPlanner.reservedByAccount(await goals.listProgress()), isEmpty);
      await goals.deleteGoal(g.id);
      expect(await goals.listProgress(), isEmpty);
    });

    test('an account with a goal is archived instead of deleted', () async {
      final a = await bank();
      await goals.createGoal(name: 'G', targetMinorUnits: 1, accountId: a.id);
      expect(await accounts.deleteOrArchive(a.id), isFalse);
    });
  });
}
