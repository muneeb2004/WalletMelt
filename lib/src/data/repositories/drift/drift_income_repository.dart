import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../types/income.dart' as domain;
import '../../../utils/recurrence.dart';
import '../../local/wallet_melt_database.dart' as local;

/// Income facts and recurring schedules (ADR-0012). Balance effects are derived
/// by [DriftAccountRepository]; nothing here stores a running total.
class DriftIncomeRepository {
  DriftIncomeRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  static String _day(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();

  // ---- incomes --------------------------------------------------------------

  Future<List<domain.Income>> listIncomes() async {
    final rows = await (_db.select(_db.incomes)
          ..where((i) => i.deletedAt.isNull())
          ..orderBy([
            (i) => OrderingTerm(expression: i.date, mode: OrderingMode.desc),
            (i) =>
                OrderingTerm(expression: i.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_incomeToDomain).toList();
  }

  Future<domain.Income> addIncome({
    required String title,
    required domain.IncomeSource source,
    required int amountMinorUnits,
    required String currency,
    required DateTime date,
    String? accountId,
    String? scheduleId,
    String? notes,
  }) async {
    if (amountMinorUnits <= 0) {
      throw ArgumentError('Income amount must be greater than zero.');
    }
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Income title is required.');
    }
    await _requireMatchingAccount(accountId, currency);
    final now = DateTime.now().toIso8601String();
    final income = domain.Income(
      id: _uuid.v4(),
      accountId: accountId,
      scheduleId: scheduleId,
      title: trimmed,
      source: source,
      amountMinorUnits: amountMinorUnits,
      currency: currency,
      date: _day(date),
      notes: _blankToNull(notes),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.incomes).insert(_incomeCompanion(income));
    return income;
  }

  Future<void> softDeleteIncome(String id) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.incomes)..where((i) => i.id.equals(id))).write(
      local.IncomesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  // ---- schedules ------------------------------------------------------------

  Future<List<domain.IncomeSchedule>> listSchedules() async {
    final rows = await (_db.select(_db.incomeSchedules)
          ..where((s) => s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm(expression: s.nextDueDate)]))
        .get();
    return rows.map(_scheduleToDomain).toList();
  }

  Future<domain.IncomeSchedule> createSchedule({
    required String title,
    required domain.IncomeSource source,
    required int amountMinorUnits,
    required String currency,
    required String cycle,
    required DateTime firstDueDate,
    String? accountId,
  }) async {
    if (amountMinorUnits <= 0) {
      throw ArgumentError('Income amount must be greater than zero.');
    }
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Income title is required.');
    }
    await _requireMatchingAccount(accountId, currency);
    final now = DateTime.now().toIso8601String();
    final schedule = domain.IncomeSchedule(
      id: _uuid.v4(),
      title: trimmed,
      source: source,
      amountMinorUnits: amountMinorUnits,
      currency: currency,
      accountId: accountId,
      cycle: cycle,
      startDate: _day(firstDueDate),
      nextDueDate: _day(firstDueDate),
      status: domain.IncomeScheduleStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.incomeSchedules).insert(_scheduleCompanion(schedule));
    return schedule;
  }

  Future<void> setScheduleStatus(
      String id, domain.IncomeScheduleStatus status) async {
    await (_db.update(_db.incomeSchedules)..where((s) => s.id.equals(id)))
        .write(local.IncomeSchedulesCompanion(
      status: Value(status.name),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> deleteSchedule(String id) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.incomeSchedules)..where((s) => s.id.equals(id)))
        .write(local.IncomeSchedulesCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Active schedules whose next occurrence is on or before [today].
  Future<List<domain.IncomeSchedule>> listDue(DateTime today) async {
    final cutoff = DateTime(today.year, today.month, today.day);
    final all = await listSchedules();
    return [
      for (final s in all)
        if (s.isActive &&
            (DateTime.tryParse(s.nextDueDate)?.compareTo(cutoff) ?? 1) <= 0)
          s,
    ];
  }

  /// Records the due occurrence as received and advances the schedule, in one
  /// transaction. The amount and date default to the schedule's values.
  Future<domain.Income> confirmReceived(
    String scheduleId, {
    int? amountMinorUnits,
    DateTime? receivedOn,
  }) {
    return _db.transaction(() async {
      final schedule = await _requireSchedule(scheduleId);
      final due = DateTime.parse(schedule.nextDueDate);
      final income = await addIncome(
        title: schedule.title,
        source: schedule.source,
        amountMinorUnits: amountMinorUnits ?? schedule.amountMinorUnits,
        currency: schedule.currency,
        date: receivedOn ?? due,
        accountId: schedule.accountId,
        scheduleId: schedule.id,
      );
      await _advance(schedule);
      return income;
    });
  }

  /// Advances the schedule past the due occurrence without recording income.
  Future<void> skipOccurrence(String scheduleId) {
    return _db.transaction(() async {
      await _advance(await _requireSchedule(scheduleId));
    });
  }

  // ---- internals ------------------------------------------------------------

  Future<void> _advance(domain.IncomeSchedule schedule) async {
    final due = DateTime.parse(schedule.nextDueDate);
    final next = advanceByCycle(schedule.cycle, due, schedule.anchorDay);
    await (_db.update(_db.incomeSchedules)
          ..where((s) => s.id.equals(schedule.id)))
        .write(local.IncomeSchedulesCompanion(
      nextDueDate: Value(_day(next)),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<domain.IncomeSchedule> _requireSchedule(String id) async {
    final row = await (_db.select(_db.incomeSchedules)
          ..where((s) => s.id.equals(id) & s.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) throw StateError('Income schedule not found.');
    return _scheduleToDomain(row);
  }

  Future<void> _requireMatchingAccount(String? accountId, String currency) async {
    if (accountId == null) return;
    final row = await (_db.select(_db.accounts)
          ..where((a) => a.id.equals(accountId) & a.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) throw StateError('Account not found.');
    if (row.currency != currency) {
      throw ArgumentError(
          'Income currency ($currency) must match the account currency (${row.currency}).');
    }
  }

  static String? _blankToNull(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  local.IncomesCompanion _incomeCompanion(domain.Income i) {
    return local.IncomesCompanion.insert(
      id: i.id,
      accountId: Value(i.accountId),
      scheduleId: Value(i.scheduleId),
      title: i.title,
      source: i.source.name,
      amountMinorUnits: i.amountMinorUnits,
      currency: i.currency,
      date: i.date,
      notes: Value(i.notes),
      createdAt: i.createdAt,
      updatedAt: i.updatedAt,
    );
  }

  local.IncomeSchedulesCompanion _scheduleCompanion(domain.IncomeSchedule s) {
    return local.IncomeSchedulesCompanion.insert(
      id: s.id,
      title: s.title,
      source: s.source.name,
      amountMinorUnits: s.amountMinorUnits,
      currency: s.currency,
      accountId: Value(s.accountId),
      cycle: s.cycle,
      startDate: s.startDate,
      nextDueDate: s.nextDueDate,
      status: Value(s.status.name),
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
    );
  }

  domain.Income _incomeToDomain(local.Income r) => domain.Income(
        id: r.id,
        accountId: r.accountId,
        scheduleId: r.scheduleId,
        title: r.title,
        source: domain.incomeSourceFromName(r.source),
        amountMinorUnits: r.amountMinorUnits,
        currency: r.currency,
        date: r.date,
        notes: r.notes,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
      );

  domain.IncomeSchedule _scheduleToDomain(local.IncomeSchedule r) =>
      domain.IncomeSchedule(
        id: r.id,
        title: r.title,
        source: domain.incomeSourceFromName(r.source),
        amountMinorUnits: r.amountMinorUnits,
        currency: r.currency,
        accountId: r.accountId,
        cycle: r.cycle,
        startDate: r.startDate,
        nextDueDate: r.nextDueDate,
        status: r.status == 'paused'
            ? domain.IncomeScheduleStatus.paused
            : domain.IncomeScheduleStatus.active,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
      );
}
