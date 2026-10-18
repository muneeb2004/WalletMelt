import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../analytics/committee_planner.dart';
import '../../../types/committee.dart' as domain;
import '../../local/wallet_melt_database.dart' as local;

/// Committees (BC) and their confirmed installments and payout (ADR-0016).
/// Nothing is posted automatically; the account balance effect is derived by
/// [DriftAccountRepository] from the recorded events.
class DriftCommitteeRepository {
  DriftCommitteeRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  static String _day(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();

  // ---- reads ----------------------------------------------------------------

  Future<List<domain.CommitteeProgress>> listProgress() async {
    final committees = await (_db.select(_db.committees)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([
            (c) => OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    if (committees.isEmpty) return const [];
    final events = await (_db.select(_db.committeeEvents)
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm(expression: e.monthIndex)]))
        .get();
    final byCommittee = <String, List<domain.CommitteeEvent>>{};
    for (final e in events) {
      byCommittee.putIfAbsent(e.committeeId, () => []).add(_eventToDomain(e));
    }
    return [
      for (final c in committees)
        domain.CommitteeProgress(
          committee: _committeeToDomain(c),
          events: byCommittee[c.id] ?? const [],
        ),
    ];
  }

  // ---- committees -----------------------------------------------------------

  Future<domain.Committee> create({
    required String name,
    required int monthlyMinorUnits,
    required int memberCount,
    required int payoutMonth,
    required DateTime startDate,
    required String currency,
    int? payoutMinorUnits,
    String? accountId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Committee name is required.');
    if (monthlyMinorUnits <= 0) {
      throw ArgumentError('Monthly amount must be greater than zero.');
    }
    if (memberCount < 2 || memberCount > 60) {
      throw ArgumentError('A committee needs between 2 and 60 members.');
    }
    if (payoutMonth < 1 || payoutMonth > memberCount) {
      throw ArgumentError('Your payout month must be within 1 and $memberCount.');
    }
    final pot = payoutMinorUnits ??
        CommitteePlanner.defaultPayout(monthlyMinorUnits, memberCount);
    if (pot <= 0) throw ArgumentError('Payout must be greater than zero.');
    final accountCurrency = await _requireUsableAccount(accountId, currency);
    final now = DateTime.now().toIso8601String();
    final committee = domain.Committee(
      id: _uuid.v4(),
      name: trimmed,
      monthlyMinorUnits: monthlyMinorUnits,
      memberCount: memberCount,
      payoutMonth: payoutMonth,
      payoutMinorUnits: pot,
      currency: accountCurrency ?? currency,
      accountId: accountId,
      startDate: _day(startDate),
      status: domain.CommitteeStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.committees).insert(local.CommitteesCompanion.insert(
          id: committee.id,
          name: committee.name,
          monthlyMinorUnits: committee.monthlyMinorUnits,
          memberCount: committee.memberCount,
          payoutMonth: committee.payoutMonth,
          payoutMinorUnits: committee.payoutMinorUnits,
          currency: committee.currency,
          accountId: Value(committee.accountId),
          startDate: committee.startDate,
          status: Value(committee.status.name),
          createdAt: now,
          updatedAt: now,
        ));
    return committee;
  }

  /// Links or unlinks the account (active, same currency).
  Future<void> setAccount(String committeeId, String? accountId) async {
    final committee = await _requireCommittee(committeeId);
    await _requireUsableAccount(accountId, committee.currency);
    await (_db.update(_db.committees)..where((c) => c.id.equals(committeeId)))
        .write(local.CommitteesCompanion(
      accountId: Value(accountId),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  /// Records an installment the user actually paid. Defaults to the monthly
  /// amount on the scheduled due date.
  Future<domain.CommitteeEvent> recordInstallment(
    String committeeId,
    int monthIndex, {
    int? amountMinorUnits,
    DateTime? date,
    String? notes,
  }) {
    return _record(
      committeeId,
      domain.CommitteeEventKind.installment,
      monthIndex,
      amountMinorUnits,
      date,
      notes,
    );
  }

  /// Records the payout the user actually received (their turn month).
  Future<domain.CommitteeEvent> recordPayout(
    String committeeId, {
    int? amountMinorUnits,
    DateTime? date,
    String? notes,
  }) async {
    final committee = await _requireCommittee(committeeId);
    return _record(
      committeeId,
      domain.CommitteeEventKind.payout,
      committee.payoutMonth,
      amountMinorUnits,
      date,
      notes,
    );
  }

  /// Removes a recorded event (soft delete) and reopens a completed committee.
  Future<void> undoEvent(String eventId) {
    return _db.transaction(() async {
      final event = await (_db.select(_db.committeeEvents)
            ..where((e) => e.id.equals(eventId) & e.deletedAt.isNull()))
          .getSingleOrNull();
      if (event == null) return;
      final now = DateTime.now().toIso8601String();
      await (_db.update(_db.committeeEvents)..where((e) => e.id.equals(eventId)))
          .write(local.CommitteeEventsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
      await _setStatusIf(
        event.committeeId,
        from: domain.CommitteeStatus.completed,
        to: domain.CommitteeStatus.active,
      );
    });
  }

  Future<void> archive(String committeeId) =>
      _setStatus(committeeId, domain.CommitteeStatus.archived);

  Future<void> reopen(String committeeId) =>
      _setStatus(committeeId, domain.CommitteeStatus.active);

  Future<void> delete(String committeeId) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.committees)..where((c) => c.id.equals(committeeId)))
        .write(local.CommitteesCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  // ---- internals ------------------------------------------------------------

  Future<domain.CommitteeEvent> _record(
    String committeeId,
    domain.CommitteeEventKind kind,
    int monthIndex,
    int? amountMinorUnits,
    DateTime? date,
    String? notes,
  ) {
    return _db.transaction(() async {
      final committee = await _requireCommittee(committeeId);
      if (committee.status == domain.CommitteeStatus.archived.name) {
        throw StateError('Reopen the committee first.');
      }
      if (monthIndex < 1 || monthIndex > committee.memberCount) {
        throw ArgumentError('Month must be within 1 and ${committee.memberCount}.');
      }
      final amount = amountMinorUnits ??
          (kind == domain.CommitteeEventKind.installment
              ? committee.monthlyMinorUnits
              : committee.payoutMinorUnits);
      if (amount <= 0) throw ArgumentError('Amount must be greater than zero.');
      final existing = await (_db.select(_db.committeeEvents)
            ..where((e) =>
                e.committeeId.equals(committeeId) &
                e.kind.equals(kind.name) &
                e.monthIndex.equals(monthIndex) &
                e.deletedAt.isNull()))
          .getSingleOrNull();
      if (existing != null) {
        throw StateError(kind == domain.CommitteeEventKind.installment
            ? 'Month $monthIndex is already recorded.'
            : 'The payout is already recorded.');
      }
      final due = CommitteePlanner.dueDate(_committeeToDomain(committee), monthIndex);
      final now = DateTime.now().toIso8601String();
      final event = domain.CommitteeEvent(
        id: _uuid.v4(),
        committeeId: committeeId,
        kind: kind,
        monthIndex: monthIndex,
        amountMinorUnits: amount,
        date: _day(date ?? due),
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await _db.into(_db.committeeEvents).insert(
            local.CommitteeEventsCompanion.insert(
              id: event.id,
              committeeId: committeeId,
              kind: kind.name,
              monthIndex: monthIndex,
              amountMinorUnits: amount,
              date: event.date,
              notes: Value(event.notes),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _completeIfDone(committee);
      return event;
    });
  }

  Future<void> _completeIfDone(local.Committee committee) async {
    final rows = await (_db.select(_db.committeeEvents)
          ..where((e) =>
              e.committeeId.equals(committee.id) & e.deletedAt.isNull()))
        .get();
    final installments = {
      for (final e in rows)
        if (e.kind == domain.CommitteeEventKind.installment.name) e.monthIndex,
    };
    final payout = rows.any((e) => e.kind == domain.CommitteeEventKind.payout.name);
    if (installments.length >= committee.memberCount && payout) {
      await _setStatus(committee.id, domain.CommitteeStatus.completed);
    }
  }

  Future<void> _setStatus(String id, domain.CommitteeStatus status) async {
    await (_db.update(_db.committees)..where((c) => c.id.equals(id))).write(
      local.CommitteesCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> _setStatusIf(
    String id, {
    required domain.CommitteeStatus from,
    required domain.CommitteeStatus to,
  }) async {
    final row = await (_db.select(_db.committees)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (row != null && row.status == from.name) await _setStatus(id, to);
  }

  Future<local.Committee> _requireCommittee(String id) async {
    final row = await (_db.select(_db.committees)
          ..where((c) => c.id.equals(id) & c.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) throw StateError('Committee not found.');
    return row;
  }

  /// Returns the account currency when [accountId] is usable, null when no
  /// account is given. Throws for archived, missing or other-currency accounts.
  Future<String?> _requireUsableAccount(String? accountId, String currency) async {
    if (accountId == null) return null;
    final account = await (_db.select(_db.accounts)
          ..where((a) => a.id.equals(accountId) & a.deletedAt.isNull()))
        .getSingleOrNull();
    if (account == null || account.isArchived) {
      throw StateError('Choose an active account.');
    }
    if (account.currency != currency) {
      throw ArgumentError(
          'Account currency (${account.currency}) must match the committee currency ($currency).');
    }
    return account.currency;
  }

  domain.Committee _committeeToDomain(local.Committee r) => domain.Committee(
        id: r.id,
        name: r.name,
        monthlyMinorUnits: r.monthlyMinorUnits,
        memberCount: r.memberCount,
        payoutMonth: r.payoutMonth,
        payoutMinorUnits: r.payoutMinorUnits,
        currency: r.currency,
        accountId: r.accountId,
        startDate: r.startDate,
        status: domain.committeeStatusFromName(r.status),
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
      );

  domain.CommitteeEvent _eventToDomain(local.CommitteeEvent r) =>
      domain.CommitteeEvent(
        id: r.id,
        committeeId: r.committeeId,
        kind: domain.committeeEventKindFromName(r.kind),
        monthIndex: r.monthIndex,
        amountMinorUnits: r.amountMinorUnits,
        date: r.date,
        notes: r.notes,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
      );
}
