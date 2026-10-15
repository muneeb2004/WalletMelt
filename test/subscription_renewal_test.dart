import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' as local;
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_debt_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_subscription_repository.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/debt.dart' as wm_debt;
import 'package:wallet_melt/src/types/expense.dart' as wm_expense;
import 'package:wallet_melt/src/types/subscription.dart';

Subscription _sub({
  required String start,
  String cycle = 'monthly',
  String? next,
  String id = 's1',
}) {
  return Subscription(
    id: id,
    name: 'Netflix',
    categoryId: 'grocery',
    amount: 100,
    currency: 'PKR',
    startDate: start,
    nextOccurrenceDate: next ?? start,
    billingCycle: cycle,
    status: SubscriptionStatus.active,
    createdAt: '2026-01-01T00:00:00.000',
    updatedAt: '2026-01-01T00:00:00.000',
  );
}

String _ymd(DateTime d) => d.toIso8601String().substring(0, 10);

class _FakeCategoryRepo extends Fake implements DriftCategoryRepository {}

class _FakeBudgetRepo extends Fake implements DriftBudgetRepository {}

/// Throws on the Nth `create` call to simulate a mid-loop failure.
class _FailingExpenseRepo extends DriftExpenseRepository {
  _FailingExpenseRepo(super.db, {required this.failOnCall});
  final int failOnCall;
  int calls = 0;

  @override
  Future<wm_expense.Expense> create(wm_expense.ExpenseDraft draft) async {
    calls++;
    if (calls == failOnCall) throw StateError('boom');
    return super.create(draft);
  }
}

void main() {
  group('renewal date maths', () {
    test('monthly from Jan 31 clamps to month end without drifting', () {
      final sub = _sub(start: '2026-01-31');
      final feb = sub.calculateNextRenewalDate(DateTime(2026, 1, 31));
      expect(_ymd(feb), '2026-02-28');
      final mar = sub.calculateNextRenewalDate(feb);
      expect(_ymd(mar), '2026-03-31');
      expect(_ymd(sub.calculateNextRenewalDate(mar)), '2026-04-30');
    });

    test('annual from Feb 29 stays on Feb 28/29 across years', () {
      final sub = _sub(start: '2028-02-29', cycle: 'annual');
      var d = DateTime(2028, 2, 29);
      final seen = <String>[];
      for (var i = 0; i < 4; i++) {
        d = sub.calculateNextRenewalDate(d);
        seen.add(_ymd(d));
      }
      expect(seen, ['2029-02-28', '2030-02-28', '2031-02-28', '2032-02-29']);
    });

    test('quarterly and semi-annual keep the anchor day', () {
      final q = _sub(start: '2026-01-31', cycle: 'quarterly');
      expect(_ymd(q.calculateNextRenewalDate(DateTime(2026, 1, 31))), '2026-04-30');
      final s = _sub(start: '2026-08-31', cycle: 'semi-annual');
      expect(_ymd(s.calculateNextRenewalDate(DateTime(2026, 8, 31))), '2027-02-28');
    });

    test('custom intervals add calendar days; non-positive falls back to 30', () {
      expect(_ymd(_sub(start: '2026-03-01', cycle: 'custom_45').calculateNextRenewalDate(DateTime(2026, 3, 1))), '2026-04-15');
      expect(_ymd(_sub(start: '2026-03-01', cycle: 'custom_0').calculateNextRenewalDate(DateTime(2026, 3, 1))), '2026-03-31');
      expect(_ymd(_sub(start: '2026-03-01', cycle: 'custom_-5').calculateNextRenewalDate(DateTime(2026, 3, 1))), '2026-03-31');
    });
  });

  group('renewal engine', () {
    late local.WalletMeltDatabase db;
    setUp(() => db = local.WalletMeltDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    AppState stateFor(DriftExpenseRepository expenses, DriftSubscriptionRepository subs) {
      return AppState.test(
        driftCategoryRepository: _FakeCategoryRepo(),
        driftBudgetRepository: _FakeBudgetRepo(),
        driftExpenseRepository: expenses,
        driftSubscriptionRepository: subs,
      );
    }

    test('a failure mid catch-up rolls back: no partial expenses, date unchanged', () async {
      final subs = DriftSubscriptionRepository(db);
      final expenses = _FailingExpenseRepo(db, failOnCall: 2);
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 75));
      final start = _ymd(DateTime(threeMonthsAgo.year, threeMonthsAgo.month, 1));
      await subs.create(_sub(start: start));

      await stateFor(expenses, subs).processSubscriptionRenewals();

      expect(expenses.calls, greaterThanOrEqualTo(2), reason: 'second create threw');
      expect(await expenses.listActive(), isEmpty);
      expect((await subs.listAll()).single.nextOccurrenceDate, start);
    });

    test('a later healthy run generates each due renewal exactly once', () async {
      final subs = DriftSubscriptionRepository(db);
      final expenses = DriftExpenseRepository(db);
      final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 62));
      final start = _ymd(DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 1));
      await subs.create(_sub(start: start));
      final state = stateFor(expenses, subs);

      await state.processSubscriptionRenewals();
      final firstCount = (await expenses.listActive()).length;
      expect(firstCount, greaterThanOrEqualTo(2));

      await state.processSubscriptionRenewals();
      expect((await expenses.listActive()).length, firstCount,
          reason: 'second run must be a no-op');
      expect(
        (await subs.listAll()).single.nextOccurrenceDate.compareTo(_ymd(DateTime.now())),
        greaterThan(0),
      );
    });

    test('overlapping runs share one in-flight pass (no duplicates)', () async {
      final subs = DriftSubscriptionRepository(db);
      final expenses = DriftExpenseRepository(db);
      final today = _ymd(DateTime.now());
      await subs.create(_sub(start: today));
      final state = stateFor(expenses, subs);

      final a = state.processSubscriptionRenewals();
      final b = state.processSubscriptionRenewals();
      expect(identical(a, b), isTrue);
      await Future.wait([a, b]);
      expect(await expenses.listActive(), hasLength(1));
    });

    test('a malformed next date is skipped without aborting other subscriptions', () async {
      final subs = DriftSubscriptionRepository(db);
      final expenses = DriftExpenseRepository(db);
      await subs.create(_sub(start: '2026-01-01', next: 'garbage', id: 'bad'));
      await subs.create(_sub(start: _ymd(DateTime.now()), id: 'good'));

      await stateFor(expenses, subs).processSubscriptionRenewals();

      expect(await expenses.listActive(), hasLength(1));
    });
  });

  group('minor-unit columns are written by the repositories', () {
    late local.WalletMeltDatabase db;
    setUp(() => db = local.WalletMeltDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('new expenses store integer minor units', () async {
      final repo = DriftExpenseRepository(db);
      final created = await repo.create(wm_expense.ExpenseDraft(
        amount: 1200.5,
        currency: 'PKR',
        categoryId: 'grocery',
        title: 'Weekly',
        date: DateTime(2026, 6, 14),
        subtotalAmount: 1000.25,
        taxAmount: 200.25,
      ));
      final row = await db
          .customSelect('SELECT amountMinorUnits a, subtotalAmountMinorUnits s, taxAmountMinorUnits t FROM expenses WHERE id = ?',
              variables: [Variable.withString(created.id)])
          .getSingle();
      expect(row.read<int>('a'), 120050);
      expect(row.read<int>('s'), 100025);
      expect(row.read<int>('t'), 20025);
    });

    test('debts keep exact minor units across repayments (no float drift)', () async {
      final repo = DriftDebtRepository(db);
      await repo.createDebt(wm_debt.DebtRecord(
        id: 'd1',
        personName: 'Ali',
        type: wm_debt.DebtType.owedToMe,
        principalAmount: 0.3,
        remainingAmount: 0.3,
        currency: 'PKR',
        createdAt: '2026-06-01T00:00:00.000',
        status: wm_debt.DebtStatus.active,
      ));
      await repo.addRepayment(wm_debt.DebtRepayment(
          id: 'r1', debtId: 'd1', amount: 0.1, createdAt: '2026-06-02T00:00:00.000'));

      var row = await db.customSelect("SELECT remainingAmount r, remainingAmountMinorUnits m, principalAmountMinorUnits p FROM debt_records WHERE id='d1'").getSingle();
      expect(row.read<double>('r'), 0.2);
      expect(row.read<int>('m'), 20);
      expect(row.read<int>('p'), 30);

      await repo.addRepayment(wm_debt.DebtRepayment(
          id: 'r2', debtId: 'd1', amount: 0.2, createdAt: '2026-06-03T00:00:00.000'));
      row = await db.customSelect("SELECT remainingAmount r, remainingAmountMinorUnits m, status s FROM debt_records WHERE id='d1'").getSingle();
      expect(row.read<double>('r'), 0.0);
      expect(row.read<int>('m'), 0);
      expect(row.read<String>('s'), 'settled');
    });
  });
}
