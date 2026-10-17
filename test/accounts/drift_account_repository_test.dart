import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/balance_calculator.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' show WalletMeltDatabase;
import 'package:wallet_melt/src/data/repositories/drift/drift_account_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/types/account.dart';
import 'package:wallet_melt/src/types/expense.dart';

void main() {
  late WalletMeltDatabase db;
  late DriftAccountRepository accounts;
  late DriftExpenseRepository expenses;

  setUp(() {
    db = WalletMeltDatabase(NativeDatabase.memory());
    accounts = DriftAccountRepository(db);
    expenses = DriftExpenseRepository(db);
  });
  tearDown(() => db.close());

  Future<Expense> spend(double amount, String? accountId,
      {String currency = 'PKR', DateTime? date}) {
    return expenses.create(ExpenseDraft(
      amount: amount,
      currency: currency,
      categoryId: 'grocery',
      title: 'x',
      date: date ?? DateTime(2026, 6, 10),
      accountId: accountId,
    ));
  }

  Future<Account> makeAccount(String name,
      {String currency = 'PKR', int opening = 100000}) {
    return accounts.create(
      name: name,
      type: AccountType.bank,
      currency: currency,
      openingBalanceMinorUnits: opening,
      openingDate: DateTime(2026, 6, 1),
    );
  }

  Future<int> balance(Account a) => accounts.balanceOf(a.id);

  group('BalanceCalculator', () {
    test('formula and per-currency totals skip excluded accounts', () {
      expect(
        BalanceCalculator.balanceMinorUnits(
          openingBalanceMinorUnits: 1000,
          expenseOutflowMinorUnits: 300,
          movementNetMinorUnits: -200,
        ),
        500,
      );
      Account acc(String id, String cur,
              {bool include = true, bool archived = false}) =>
          Account(
            id: id,
            name: id,
            type: AccountType.cash,
            currency: cur,
            openingBalanceMinorUnits: 0,
            openingDate: '2026-01-01T00:00:00.000',
            createdAt: 'c',
            updatedAt: 'u',
            includeInTotal: include,
            isArchived: archived,
          );
      final totals = BalanceCalculator.totalsByCurrency([
        AccountBalance(account: acc('a', 'PKR'), balanceMinorUnits: 100),
        AccountBalance(account: acc('b', 'PKR'), balanceMinorUnits: 50),
        AccountBalance(account: acc('c', 'USD'), balanceMinorUnits: 7),
        AccountBalance(
            account: acc('d', 'PKR', include: false), balanceMinorUnits: 999),
        AccountBalance(
            account: acc('e', 'PKR', archived: true), balanceMinorUnits: 999),
      ]);
      expect(totals.map((t) => '${t.currency}:${t.minorUnits}'),
          ['PKR:150', 'USD:7']);
    });

    test('reconcileDelta is actual minus current', () {
      expect(
          BalanceCalculator.reconcileDelta(
              currentMinorUnits: 500, actualMinorUnits: 800),
          300);
    });
  });

  group('balance derivation', () {
    test('add, edit, soft-delete and restore keep the balance consistent',
        () async {
      final a = await makeAccount('Bank');
      expect(await balance(a), 100000);

      final e = await spend(250, a.id);
      expect(await balance(a), 100000 - 25000);

      await expenses.update(e.copyWith(amount: 400));
      expect(await balance(a), 100000 - 40000);

      await expenses.softDelete(e.id);
      expect(await balance(a), 100000);

      await expenses.restore(e.id);
      expect(await balance(a), 100000 - 40000);
    });

    test('unassigned, pre-opening and foreign-currency expenses are excluded',
        () async {
      final a = await makeAccount('Bank');
      await spend(100, null);
      await spend(100, a.id, date: DateTime(2026, 5, 20)); // before opening
      await spend(100, a.id, currency: 'USD');
      expect(await balance(a), 100000);
      expect(await accounts.countUnassignedExpenses(), 1);
    });

    test('legacy rows without minor units fall back to REAL amount', () async {
      final a = await makeAccount('Bank');
      final e = await spend(12.5, a.id);
      await db.customStatement(
          'UPDATE expenses SET amountMinorUnits = NULL WHERE id = ?;', [e.id]);
      expect(await balance(a), 100000 - 1250);
    });

    test('bulk assign only touches unassigned same-currency expenses',
        () async {
      final a = await makeAccount('Bank');
      await spend(10, null);
      await spend(10, null, currency: 'USD');
      final changed = await accounts.assignUnassignedExpenses(a.id);
      expect(changed, 1);
      expect(await accounts.countUnassignedExpenses(), 1);
    });

    test('editing an expense preserves its account', () async {
      final a = await makeAccount('Bank');
      final e = await spend(10, a.id);
      await expenses.update(e.copyWith(title: 'renamed'));
      final loaded = await expenses.getById(e.id);
      expect(loaded?.accountId, a.id);
    });
  });

  group('transfers and reconcile', () {
    test('same-currency transfer moves money atomically and deletes as a pair',
        () async {
      final cash = await makeAccount('Cash', opening: 50000);
      final wallet = await makeAccount('Wallet', opening: 0);
      final group = await accounts.transfer(
        fromAccountId: cash.id,
        toAccountId: wallet.id,
        amountMinorUnits: 20000,
        date: DateTime(2026, 6, 12),
      );
      expect(group, isNotEmpty);
      expect(await balance(cash), 30000);
      expect(await balance(wallet), 20000);

      final legs = await accounts.listMovements(wallet.id);
      expect(legs.single.kind, AccountMovementKind.transferIn);
      await accounts.deleteMovement(legs.single.id);
      expect(await balance(cash), 50000);
      expect(await balance(wallet), 0);
    });

    test('cross-currency transfer needs the received amount', () async {
      final pkr = await makeAccount('PKR', opening: 100000);
      final usd = await makeAccount('USD', currency: 'USD', opening: 0);
      expect(
        () => accounts.transfer(
            fromAccountId: pkr.id, toAccountId: usd.id, amountMinorUnits: 28000),
        throwsArgumentError,
      );
      await accounts.transfer(
        fromAccountId: pkr.id,
        toAccountId: usd.id,
        amountMinorUnits: 28000,
        receivedMinorUnits: 100,
      );
      expect(await balance(pkr), 72000);
      expect(await balance(usd), 100);
    });

    test('rejects same-account and non-positive transfers', () async {
      final a = await makeAccount('A');
      final b = await makeAccount('B');
      expect(
          () => accounts.transfer(
              fromAccountId: a.id, toAccountId: a.id, amountMinorUnits: 1),
          throwsArgumentError);
      expect(
          () => accounts.transfer(
              fromAccountId: a.id, toAccountId: b.id, amountMinorUnits: 0),
          throwsArgumentError);
    });

    test('reconcile writes a single reversible adjustment', () async {
      final a = await makeAccount('Bank');
      await spend(100, a.id);
      final adj = await accounts.reconcile(a.id, 80000);
      expect(adj, isNotNull);
      expect(await balance(a), 80000);
      expect(await accounts.reconcile(a.id, 80000), isNull);
      await accounts.deleteMovement(adj!.id);
      expect(await balance(a), 100000 - 10000);
    });
  });

  group('lifecycle', () {
    test('account with history is archived, empty one is deleted', () async {
      final used = await makeAccount('Used');
      final empty = await makeAccount('Empty');
      await spend(5, used.id);
      expect(await accounts.deleteOrArchive(used.id), isFalse);
      expect(await accounts.deleteOrArchive(empty.id), isTrue);
      expect((await accounts.getById(used.id))?.isArchived, isTrue);
      expect(await accounts.getById(empty.id), isNull);
      expect((await accounts.listAccounts()).map((a) => a.id), isEmpty);
    });

    test('currency cannot change once transactions exist', () async {
      final a = await makeAccount('Bank');
      await spend(5, a.id);
      expect(() => accounts.update(a.copyWith(currency: 'USD')),
          throwsStateError);
    });

    test('foreign key RESTRICT blocks hard-deleting a referenced account',
        () async {
      final a = await makeAccount('Bank');
      await spend(5, a.id);
      await db.customStatement('PRAGMA foreign_keys = ON;');
      expect(
        () => db.customStatement('DELETE FROM accounts WHERE id = ?;', [a.id]),
        throwsA(anything),
      );
    });
  });
}
