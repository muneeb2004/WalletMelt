import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../types/savings_goal.dart' as domain;
import '../../local/wallet_melt_database.dart' as local;

/// Savings goals and their set-aside contributions (ADR-0015). Saved amounts
/// are always derived from contributions; account balances are never touched.
class DriftGoalRepository {
  DriftGoalRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  static String _day(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();

  // ---- reads ----------------------------------------------------------------

  /// Non-deleted goals with their derived saved amount, newest first.
  Future<List<domain.GoalProgress>> listProgress() async {
    final rows = await _db.customSelect(
      'SELECT g.id AS id, COALESCE(SUM(c.amountMinorUnits), 0) AS saved '
      'FROM savings_goals g LEFT JOIN savings_contributions c '
      'ON c.goalId = g.id AND c.deletedAt IS NULL '
      'WHERE g.deletedAt IS NULL GROUP BY g.id;',
    ).get();
    final saved = {
      for (final r in rows) r.read<String>('id'): r.read<int>('saved'),
    };
    final goals = await (_db.select(_db.savingsGoals)
          ..where((g) => g.deletedAt.isNull())
          ..orderBy([
            (g) => OrderingTerm(expression: g.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return [
      for (final g in goals)
        domain.GoalProgress(
          goal: _goalToDomain(g),
          savedMinorUnits: saved[g.id] ?? 0,
        ),
    ];
  }

  Future<int> savedFor(String goalId) async {
    final row = await _db.customSelect(
      'SELECT COALESCE(SUM(amountMinorUnits), 0) AS s FROM savings_contributions '
      'WHERE goalId = ? AND deletedAt IS NULL;',
      variables: [Variable.withString(goalId)],
    ).getSingle();
    return row.read<int>('s');
  }

  Future<List<domain.GoalContribution>> listContributions(String goalId) async {
    final rows = await (_db.select(_db.savingsContributions)
          ..where((c) => c.goalId.equals(goalId) & c.deletedAt.isNull())
          ..orderBy([
            (c) => OrderingTerm(expression: c.date, mode: OrderingMode.desc),
            (c) => OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_contributionToDomain).toList();
  }

  // ---- goals ----------------------------------------------------------------

  Future<domain.SavingsGoal> createGoal({
    required String name,
    required int targetMinorUnits,
    required String accountId,
    DateTime? targetDate,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Goal name is required.');
    if (targetMinorUnits <= 0) {
      throw ArgumentError('Target must be greater than zero.');
    }
    final account = await (_db.select(_db.accounts)
          ..where((a) => a.id.equals(accountId) & a.deletedAt.isNull()))
        .getSingleOrNull();
    if (account == null || account.isArchived) {
      throw StateError('Choose an active account.');
    }
    final now = DateTime.now().toIso8601String();
    final goal = domain.SavingsGoal(
      id: _uuid.v4(),
      name: trimmed,
      targetMinorUnits: targetMinorUnits,
      currency: account.currency,
      accountId: accountId,
      targetDate: targetDate == null ? null : _day(targetDate),
      status: domain.GoalStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.savingsGoals).insert(local.SavingsGoalsCompanion.insert(
          id: goal.id,
          name: goal.name,
          targetMinorUnits: goal.targetMinorUnits,
          currency: goal.currency,
          accountId: goal.accountId,
          targetDate: Value(goal.targetDate),
          status: Value(goal.status.name),
          createdAt: now,
          updatedAt: now,
        ));
    return goal;
  }

  /// Sets money aside. Only active goals accept contributions.
  Future<domain.GoalContribution> setAside(
    String goalId,
    int amountMinorUnits, {
    DateTime? date,
    String? notes,
  }) async {
    if (amountMinorUnits <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
    return _db.transaction(() async {
      await _requireActive(goalId);
      return _insertContribution(goalId, amountMinorUnits, date, notes);
    });
  }

  /// Releases previously set-aside money; cannot release more than is saved.
  Future<domain.GoalContribution> release(
    String goalId,
    int amountMinorUnits, {
    DateTime? date,
    String? notes,
  }) async {
    if (amountMinorUnits <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
    return _db.transaction(() async {
      await _requireActive(goalId);
      final saved = await savedFor(goalId);
      if (amountMinorUnits > saved) {
        throw ArgumentError('You can only release what is set aside.');
      }
      return _insertContribution(goalId, -amountMinorUnits, date, notes ?? 'Released');
    });
  }

  /// Marks the goal achieved and releases whatever is still set aside, so the
  /// money becomes free to spend again while history is kept.
  Future<void> markAchieved(String goalId) {
    return _db.transaction(() async {
      await _requireActive(goalId);
      final saved = await savedFor(goalId);
      if (saved > 0) {
        await _insertContribution(goalId, -saved, null, 'Goal achieved');
      }
      await _setStatus(goalId, domain.GoalStatus.achieved);
    });
  }

  Future<void> archive(String goalId) =>
      _setStatus(goalId, domain.GoalStatus.archived);

  Future<void> reopen(String goalId) =>
      _setStatus(goalId, domain.GoalStatus.active);

  Future<void> deleteGoal(String goalId) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.savingsGoals)..where((g) => g.id.equals(goalId)))
        .write(local.SavingsGoalsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  // ---- internals ------------------------------------------------------------

  Future<void> _setStatus(String goalId, domain.GoalStatus status) async {
    await (_db.update(_db.savingsGoals)..where((g) => g.id.equals(goalId)))
        .write(local.SavingsGoalsCompanion(
      status: Value(status.name),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> _requireActive(String goalId) async {
    final row = await (_db.select(_db.savingsGoals)
          ..where((g) => g.id.equals(goalId) & g.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) throw StateError('Goal not found.');
    if (row.status != domain.GoalStatus.active.name) {
      throw StateError('Reopen the goal first.');
    }
  }

  Future<domain.GoalContribution> _insertContribution(
    String goalId,
    int amountMinorUnits,
    DateTime? date,
    String? notes,
  ) async {
    final now = DateTime.now().toIso8601String();
    final contribution = domain.GoalContribution(
      id: _uuid.v4(),
      goalId: goalId,
      amountMinorUnits: amountMinorUnits,
      date: _day(date ?? DateTime.now()),
      notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.savingsContributions).insert(
          local.SavingsContributionsCompanion.insert(
            id: contribution.id,
            goalId: goalId,
            amountMinorUnits: amountMinorUnits,
            date: contribution.date,
            notes: Value(contribution.notes),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return contribution;
  }

  domain.SavingsGoal _goalToDomain(local.SavingsGoal r) => domain.SavingsGoal(
        id: r.id,
        name: r.name,
        targetMinorUnits: r.targetMinorUnits,
        currency: r.currency,
        accountId: r.accountId,
        targetDate: r.targetDate,
        status: domain.goalStatusFromName(r.status),
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
      );

  domain.GoalContribution _contributionToDomain(local.SavingsContribution r) =>
      domain.GoalContribution(
        id: r.id,
        goalId: r.goalId,
        amountMinorUnits: r.amountMinorUnits,
        date: r.date,
        notes: r.notes,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
      );
}
