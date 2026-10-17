import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../analytics/balance_calculator.dart';
import '../../../types/account.dart' as domain;
import '../../local/wallet_melt_database.dart' as local;

class DriftAccountRepository {
  DriftAccountRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  // ---- accounts -------------------------------------------------------------

  /// Non-deleted accounts, archived ones last.
  Future<List<domain.Account>> listAccounts({bool includeArchived = false}) async {
    final query = _db.select(_db.accounts)
      ..where((a) => a.deletedAt.isNull())
      ..orderBy([
        (a) => OrderingTerm(expression: a.isArchived),
        (a) => OrderingTerm(expression: a.sortOrder),
        (a) => OrderingTerm(expression: a.name),
      ]);
    if (!includeArchived) {
      query.where((a) => a.isArchived.equals(false));
    }
    return (await query.get()).map(_accountToDomain).toList();
  }

  Future<domain.Account?> getById(String id) async {
    final row = await (_db.select(_db.accounts)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _accountToDomain(row);
  }

  Future<domain.Account> create({
    required String name,
    required domain.AccountType type,
    required String currency,
    int openingBalanceMinorUnits = 0,
    DateTime? openingDate,
    String? iconKey,
    String? colorRole,
    bool includeInTotal = true,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Account name is required.');
    }
    final now = DateTime.now();
    final opening = openingDate ?? now;
    final existing = await _db.customSelect(
        'SELECT COALESCE(MAX(sortOrder), -1) AS m FROM accounts;').getSingle();
    final account = domain.Account(
      id: _uuid.v4(),
      name: trimmed,
      type: type,
      currency: currency,
      openingBalanceMinorUnits: openingBalanceMinorUnits,
      openingDate: DateTime(opening.year, opening.month, opening.day)
          .toIso8601String(),
      iconKey: iconKey,
      colorRole: colorRole,
      sortOrder: existing.read<int>('m') + 1,
      includeInTotal: includeInTotal,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    await _db.into(_db.accounts).insert(_accountCompanion(account));
    return account;
  }

  /// Currency is immutable once movements or expenses reference the account.
  Future<void> update(domain.Account account) async {
    final existing = await getById(account.id);
    if (existing == null) return;
    if (existing.currency != account.currency &&
        await hasLinkedRows(account.id)) {
      throw StateError(
          'Currency cannot change once the account has transactions.');
    }
    final trimmed = account.name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Account name is required.');
    }
    await (_db.update(_db.accounts)..where((a) => a.id.equals(account.id)))
        .write(local.AccountsCompanion(
      name: Value(trimmed),
      type: Value(account.type.name),
      currency: Value(account.currency),
      openingBalanceMinorUnits: Value(account.openingBalanceMinorUnits),
      openingDate: Value(account.openingDate),
      iconKey: Value(account.iconKey),
      colorRole: Value(account.colorRole),
      isArchived: Value(account.isArchived),
      includeInTotal: Value(account.includeInTotal),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> setArchived(String id, bool archived) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      local.AccountsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<bool> hasLinkedRows(String accountId) async {
    final row = await _db.customSelect(
      'SELECT (SELECT COUNT(*) FROM expenses WHERE accountId = ?1) + '
      '(SELECT COUNT(*) FROM account_movements WHERE accountId = ?1) + '
      '(SELECT COUNT(*) FROM incomes WHERE accountId = ?1) + '
      '(SELECT COUNT(*) FROM income_schedules WHERE accountId = ?1) AS n;',
      variables: [Variable.withString(accountId)],
    ).getSingle();
    return row.read<int>('n') > 0;
  }

  /// Deletes an account that has no rows; otherwise archives it so history and
  /// the RESTRICT foreign keys stay intact. Returns true if hard-deleted.
  Future<bool> deleteOrArchive(String id) async {
    if (await hasLinkedRows(id)) {
      await setArchived(id, true);
      return false;
    }
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
    return true;
  }

  // ---- balances -------------------------------------------------------------

  Future<List<domain.AccountBalance>> listBalances(
      {bool includeArchived = false}) async {
    final accounts = await listAccounts(includeArchived: includeArchived);
    if (accounts.isEmpty) return const [];
    final expenseRows = await _db.customSelect(
      'SELECT a.id AS id, COALESCE(SUM(COALESCE(e.amountMinorUnits, '
      'CAST(ROUND(e.amount * 100) AS INTEGER))), 0) AS total '
      'FROM accounts a LEFT JOIN expenses e ON e.accountId = a.id '
      'AND e.deletedAt IS NULL AND e.currency = a.currency '
      'AND e.date >= a.openingDate '
      'GROUP BY a.id;',
    ).get();
    final movementRows = await _db.customSelect(
      'SELECT a.id AS id, COALESCE(SUM(m.amountMinorUnits), 0) AS total '
      'FROM accounts a LEFT JOIN account_movements m ON m.accountId = a.id '
      'AND m.deletedAt IS NULL AND m.date >= a.openingDate '
      'GROUP BY a.id;',
    ).get();
    final incomeRows = await _db.customSelect(
      'SELECT a.id AS id, COALESCE(SUM(i.amountMinorUnits), 0) AS total '
      'FROM accounts a LEFT JOIN incomes i ON i.accountId = a.id '
      'AND i.deletedAt IS NULL AND i.currency = a.currency '
      'AND i.date >= a.openingDate '
      'GROUP BY a.id;',
    ).get();
    final inflow = {
      for (final r in incomeRows) r.read<String>('id'): r.read<int>('total'),
    };
    final outflow = {
      for (final r in expenseRows) r.read<String>('id'): r.read<int>('total'),
    };
    final net = {
      for (final r in movementRows) r.read<String>('id'): r.read<int>('total'),
    };
    return [
      for (final a in accounts)
        domain.AccountBalance(
          account: a,
          balanceMinorUnits: BalanceCalculator.balanceMinorUnits(
            openingBalanceMinorUnits: a.openingBalanceMinorUnits,
            expenseOutflowMinorUnits: outflow[a.id] ?? 0,
            movementNetMinorUnits: net[a.id] ?? 0,
            incomeInflowMinorUnits: inflow[a.id] ?? 0,
          ),
        ),
    ];
  }

  Future<int> balanceOf(String accountId) async {
    final balances = await listBalances(includeArchived: true);
    for (final b in balances) {
      if (b.account.id == accountId) return b.balanceMinorUnits;
    }
    return 0;
  }

  /// Active expenses with no account (candidates for bulk assign).
  Future<int> countUnassignedExpenses() async {
    final row = await _db.customSelect(
        'SELECT COUNT(*) AS n FROM expenses WHERE accountId IS NULL AND deletedAt IS NULL;')
        .getSingle();
    return row.read<int>('n');
  }

  /// Assigns every unassigned active expense in [currency] to [accountId].
  /// Returns the number of rows changed.
  Future<int> assignUnassignedExpenses(String accountId) async {
    final account = await getById(accountId);
    if (account == null) return 0;
    return _db.customUpdate(
      'UPDATE expenses SET accountId = ?, updatedAt = ? '
      'WHERE accountId IS NULL AND deletedAt IS NULL AND currency = ?;',
      variables: [
        Variable.withString(accountId),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString(account.currency),
      ],
      updates: {_db.expenses},
      updateKind: UpdateKind.update,
    );
  }

  // ---- movements ------------------------------------------------------------

  Future<List<domain.AccountMovement>> listMovements(String accountId) async {
    final rows = await (_db.select(_db.accountMovements)
          ..where((m) => m.accountId.equals(accountId) & m.deletedAt.isNull())
          ..orderBy([
            (m) => OrderingTerm(expression: m.date, mode: OrderingMode.desc),
            (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_movementToDomain).toList();
  }

  /// Writes one reconcile adjustment so the derived balance equals
  /// [actualBalanceMinorUnits]. Returns null when already equal.
  Future<domain.AccountMovement?> reconcile(
    String accountId,
    int actualBalanceMinorUnits, {
    String? notes,
  }) async {
    return _db.transaction(() async {
      final current = await balanceOf(accountId);
      final delta = BalanceCalculator.reconcileDelta(
        currentMinorUnits: current,
        actualMinorUnits: actualBalanceMinorUnits,
      );
      if (delta == 0) return null;
      return _insertMovement(
        accountId: accountId,
        kind: domain.AccountMovementKind.adjustment,
        amountMinorUnits: delta,
        date: DateTime.now(),
        notes: notes ?? 'Balance reconciled',
      );
    });
  }

  /// Atomic two-leg transfer. Same-currency accounts use [amountMinorUnits] for
  /// both legs; cross-currency transfers must pass [receivedMinorUnits].
  Future<String> transfer({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinorUnits,
    int? receivedMinorUnits,
    DateTime? date,
    String? notes,
  }) async {
    if (fromAccountId == toAccountId) {
      throw ArgumentError('Choose two different accounts.');
    }
    if (amountMinorUnits <= 0) {
      throw ArgumentError('Transfer amount must be greater than zero.');
    }
    return _db.transaction(() async {
      final from = await getById(fromAccountId);
      final to = await getById(toAccountId);
      if (from == null || to == null) {
        throw StateError('Account not found.');
      }
      final cross = from.currency != to.currency;
      if (cross && (receivedMinorUnits == null || receivedMinorUnits <= 0)) {
        throw ArgumentError(
            'Enter the amount received for a cross-currency transfer.');
      }
      final received = cross ? receivedMinorUnits! : amountMinorUnits;
      final groupId = _uuid.v4();
      final when = date ?? DateTime.now();
      await _insertMovement(
        accountId: fromAccountId,
        kind: domain.AccountMovementKind.transferOut,
        amountMinorUnits: -amountMinorUnits,
        date: when,
        transferGroupId: groupId,
        notes: notes,
      );
      await _insertMovement(
        accountId: toAccountId,
        kind: domain.AccountMovementKind.transferIn,
        amountMinorUnits: received,
        date: when,
        transferGroupId: groupId,
        notes: notes,
      );
      return groupId;
    });
  }

  /// Soft-deletes a movement; both legs when it belongs to a transfer.
  Future<void> deleteMovement(String movementId) async {
    await _db.transaction(() async {
      final row = await (_db.select(_db.accountMovements)
            ..where((m) => m.id.equals(movementId)))
          .getSingleOrNull();
      if (row == null) return;
      final now = DateTime.now().toIso8601String();
      final companion = local.AccountMovementsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      );
      final group = row.transferGroupId;
      if (group != null) {
        await (_db.update(_db.accountMovements)
              ..where((m) => m.transferGroupId.equals(group)))
            .write(companion);
      } else {
        await (_db.update(_db.accountMovements)
              ..where((m) => m.id.equals(movementId)))
            .write(companion);
      }
    });
  }

  Future<domain.AccountMovement> _insertMovement({
    required String accountId,
    required domain.AccountMovementKind kind,
    required int amountMinorUnits,
    required DateTime date,
    String? transferGroupId,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final movement = domain.AccountMovement(
      id: _uuid.v4(),
      accountId: accountId,
      kind: kind,
      amountMinorUnits: amountMinorUnits,
      date: DateTime(date.year, date.month, date.day).toIso8601String(),
      transferGroupId: transferGroupId,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.accountMovements).insert(
          local.AccountMovementsCompanion.insert(
            id: movement.id,
            accountId: movement.accountId,
            kind: kind.storageName,
            amountMinorUnits: movement.amountMinorUnits,
            date: movement.date,
            transferGroupId: Value(movement.transferGroupId),
            notes: Value(movement.notes),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return movement;
  }

  local.AccountsCompanion _accountCompanion(domain.Account a) {
    return local.AccountsCompanion.insert(
      id: a.id,
      name: a.name,
      type: a.type.name,
      currency: a.currency,
      openingBalanceMinorUnits: Value(a.openingBalanceMinorUnits),
      openingDate: a.openingDate,
      iconKey: Value(a.iconKey),
      colorRole: Value(a.colorRole),
      sortOrder: Value(a.sortOrder),
      isArchived: Value(a.isArchived),
      includeInTotal: Value(a.includeInTotal),
      createdAt: a.createdAt,
      updatedAt: a.updatedAt,
    );
  }

  domain.Account _accountToDomain(local.Account row) {
    return domain.Account(
      id: row.id,
      name: row.name,
      type: domain.accountTypeFromName(row.type),
      currency: row.currency,
      openingBalanceMinorUnits: row.openingBalanceMinorUnits,
      openingDate: row.openingDate,
      iconKey: row.iconKey,
      colorRole: row.colorRole,
      sortOrder: row.sortOrder,
      isArchived: row.isArchived,
      includeInTotal: row.includeInTotal,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  domain.AccountMovement _movementToDomain(local.AccountMovement row) {
    return domain.AccountMovement(
      id: row.id,
      accountId: row.accountId,
      kind: domain.AccountMovementKindStorage.fromStorage(row.kind),
      amountMinorUnits: row.amountMinorUnits,
      date: row.date,
      transferGroupId: row.transferGroupId,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
