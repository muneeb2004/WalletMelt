import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/committee_planner.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_committee_repository.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/committee.dart';

Committee _committee({
  int monthly = 10000,
  int members = 6,
  int payoutMonth = 3,
  int? payout,
  String start = '2026-01-31T00:00:00.000',
  CommitteeStatus status = CommitteeStatus.active,
}) =>
    Committee(
      id: 'c1',
      name: 'Office BC',
      monthlyMinorUnits: monthly,
      memberCount: members,
      payoutMonth: payoutMonth,
      payoutMinorUnits: payout ?? monthly * members,
      currency: 'PKR',
      startDate: start,
      status: status,
      createdAt: 't',
      updatedAt: 't',
    );

CommitteeEvent _event(CommitteeEventKind kind, int month, int amount,
        {String? deletedAt}) =>
    CommitteeEvent(
      id: '${kind.name}$month',
      committeeId: 'c1',
      kind: kind,
      monthIndex: month,
      amountMinorUnits: amount,
      date: '2026-01-01T00:00:00.000',
      createdAt: 't',
      updatedAt: 't',
      deletedAt: deletedAt,
    );

void main() {
  group('CommitteePlanner', () {
    test('due dates keep the month-end anchor', () {
      final c = _committee();
      expect(CommitteePlanner.dueDate(c, 1), DateTime(2026, 1, 31));
      expect(CommitteePlanner.dueDate(c, 2), DateTime(2026, 2, 28));
      expect(CommitteePlanner.dueDate(c, 3), DateTime(2026, 3, 31));
      expect(CommitteePlanner.dueDate(c, 6), DateTime(2026, 6, 30));
    });

    test('due items: unpaid installments and the payout once its month comes',
        () {
      final c = _committee(payoutMonth: 2);
      final progress = CommitteeProgress(
        committee: c,
        events: [_event(CommitteeEventKind.installment, 1, 10000)],
      );
      // On 28 Feb: month 2 installment and the payout (turn month 2) are due.
      var items = CommitteePlanner.dueItems([progress], DateTime(2026, 2, 28));
      expect(items.map((i) => '${i.kind.name}${i.monthIndex}').toList(),
          ['installment2', 'payout2']);
      expect(items.last.amountMinorUnits, c.payoutMinorUnits);

      // Nothing is due before the date.
      items = CommitteePlanner.dueItems([progress], DateTime(2026, 2, 27));
      expect(items, isEmpty);

      // Overdue months pile up oldest first.
      final empty = CommitteeProgress(committee: _committee(), events: const []);
      items = CommitteePlanner.dueItems([empty], DateTime(2026, 4, 30));
      expect(items.map((i) => i.monthIndex).toList(), [1, 2, 3, 3, 4]);
      expect(items.map((i) => i.kind).toList().sublist(2, 4), [
        CommitteeEventKind.installment,
        CommitteeEventKind.payout,
      ]);
    });

    test('inactive and recorded items produce nothing', () {
      final done = CommitteeProgress(
        committee: _committee(status: CommitteeStatus.archived),
        events: const [],
      );
      expect(CommitteePlanner.dueItems([done], DateTime(2027, 1, 1)), isEmpty);
      final paid = CommitteeProgress(
        committee: _committee(members: 2, payoutMonth: 1),
        events: [
          _event(CommitteeEventKind.installment, 1, 1),
          _event(CommitteeEventKind.installment, 2, 1),
          _event(CommitteeEventKind.payout, 1, 1),
        ],
      );
      expect(CommitteePlanner.dueItems([paid], DateTime(2027, 1, 1)), isEmpty);
    });

    test('progress totals ignore deleted events', () {
      final p = CommitteeProgress(
        committee: _committee(),
        events: [
          _event(CommitteeEventKind.installment, 1, 10000),
          _event(CommitteeEventKind.installment, 2, 10000),
          _event(CommitteeEventKind.installment, 3, 10000,
              deletedAt: '2026-02-01'),
          _event(CommitteeEventKind.payout, 3, 55000),
        ],
      );
      expect(p.paidCount, 2);
      expect(p.paidMinorUnits, 20000);
      expect(p.nextInstallmentMonth, 3);
      expect(p.remainingInstallments, 4);
      expect(p.receivedMinorUnits, 55000);
      expect(CommitteePlanner.netSoFar(p), 35000);
      expect(CommitteePlanner.expectedNet(_committee(payout: 70000)), 10000);
      expect(p.isFullyRecorded, isFalse);
    });
  });

  group('DriftCommitteeRepository', () {
    late WalletMeltDatabase db;
    late DriftCommitteeRepository committees;
    late DriftAccountRepository accounts;

    setUp(() {
      db = WalletMeltDatabase(NativeDatabase.memory());
      committees = DriftCommitteeRepository(db);
      accounts = DriftAccountRepository(db);
    });
    tearDown(() => db.close());

    Future<Account> bank({String currency = 'PKR'}) => accounts.create(
          name: 'Bank',
          type: AccountType.bank,
          currency: currency,
          openingBalanceMinorUnits: 1000000,
          openingDate: DateTime(2026, 1, 1),
        );

    Future<Committee> make({String? accountId, int members = 3, int turn = 2}) =>
        committees.create(
          name: 'Family BC',
          monthlyMinorUnits: 10000,
          memberCount: members,
          payoutMonth: turn,
          startDate: DateTime(2026, 6, 10),
          currency: 'PKR',
          accountId: accountId,
        );

    test('installments reduce and the payout raises the linked balance',
        () async {
      final a = await bank();
      final c = await make(accountId: a.id);
      expect(c.payoutMinorUnits, 30000, reason: 'defaults to monthly x members');
      expect(await accounts.balanceOf(a.id), 1000000);

      await committees.recordInstallment(c.id, 1);
      await committees.recordInstallment(c.id, 2, amountMinorUnits: 12000);
      expect(await accounts.balanceOf(a.id), 1000000 - 10000 - 12000);

      await committees.recordPayout(c.id);
      expect(await accounts.balanceOf(a.id), 1000000 - 22000 + 30000);
    });

    test('unlinked committees never touch a balance', () async {
      final a = await bank();
      final c = await make();
      await committees.recordInstallment(c.id, 1);
      expect(await accounts.balanceOf(a.id), 1000000);
    });

    test('completes when all installments and the payout are recorded, undo reopens',
        () async {
      final c = await make(members: 2, turn: 1);
      await committees.recordInstallment(c.id, 1);
      await committees.recordPayout(c.id);
      expect((await committees.listProgress()).single.committee.status,
          CommitteeStatus.active);
      await committees.recordInstallment(c.id, 2);
      var p = (await committees.listProgress()).single;
      expect(p.committee.status, CommitteeStatus.completed);
      expect(p.isFullyRecorded, isTrue);

      await committees.undoEvent(p.events.firstWhere((e) => e.monthIndex == 2).id);
      p = (await committees.listProgress()).single;
      expect(p.committee.status, CommitteeStatus.active);
      expect(p.paidCount, 1);
    });

    test('validations', () async {
      final a = await bank();
      final usd = await bank(currency: 'USD');
      final c = await make();
      expect(() => committees.recordInstallment(c.id, 1).then((_) => committees.recordInstallment(c.id, 1)),
          throwsStateError, reason: 'duplicate month');
      expect(() => committees.recordInstallment(c.id, 4), throwsArgumentError);
      expect(() => committees.recordInstallment(c.id, 0), throwsArgumentError);
      expect(() => committees.recordInstallment(c.id, 2, amountMinorUnits: 0),
          throwsArgumentError);
      await committees.recordPayout(c.id);
      expect(() => committees.recordPayout(c.id), throwsStateError);
      expect(() => committees.create(name: ' ', monthlyMinorUnits: 1, memberCount: 3, payoutMonth: 1, startDate: DateTime(2026), currency: 'PKR'),
          throwsArgumentError);
      expect(() => committees.create(name: 'x', monthlyMinorUnits: 1, memberCount: 1, payoutMonth: 1, startDate: DateTime(2026), currency: 'PKR'),
          throwsArgumentError);
      expect(() => committees.create(name: 'x', monthlyMinorUnits: 1, memberCount: 3, payoutMonth: 4, startDate: DateTime(2026), currency: 'PKR'),
          throwsArgumentError);
      expect(() => committees.setAccount(c.id, usd.id), throwsArgumentError);
      await committees.setAccount(c.id, a.id);
      await accounts.setArchived(a.id, true);
      expect(() => committees.setAccount(c.id, a.id), throwsStateError);
    });

    test('a linked account is archived instead of deleted; deleted committee stops counting',
        () async {
      final a = await bank();
      final c = await make(accountId: a.id);
      await committees.recordInstallment(c.id, 1);
      expect(await accounts.deleteOrArchive(a.id), isFalse);
      await committees.delete(c.id);
      expect(await accounts.balanceOf(a.id), 1000000);
      expect(await committees.listProgress(), isEmpty);
    });
  });
}
