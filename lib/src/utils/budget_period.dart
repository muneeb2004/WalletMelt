import 'package:intl/intl.dart';

/// Budget period whose first day is [startDay] of each month (ADR-0013).
///
/// A period is identified by the month in which it **starts**: with start day
/// 25, period `2026-06` runs 25 Jun 2026 to 24 Jul 2026 inclusive. Start day 1
/// is the calendar month and reproduces the pre-ADR-0013 behaviour exactly.
///
/// All dates are compared as whole days at local midnight.
class BudgetPeriod {
  const BudgetPeriod([this.startDay = 1])
      : assert(startDay >= 1 && startDay <= maxStartDay);

  /// Days 29 to 31 are not offered so a period always starts on a real date.
  static const int maxStartDay = 28;

  static const BudgetPeriod calendar = BudgetPeriod(1);

  final int startDay;

  bool get isCalendarMonth => startDay == 1;

  /// Clamps arbitrary input (e.g. old settings) into the supported range.
  static BudgetPeriod fromStartDay(int? day) =>
      BudgetPeriod((day ?? 1).clamp(1, maxStartDay));

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The period (named by its start month) that contains [date].
  DateTime periodOf(DateTime date) {
    final d = _dayOf(date);
    return d.day >= startDay
        ? DateTime(d.year, d.month)
        : DateTime(d.year, d.month - 1);
  }

  /// First day of [month]'s period.
  DateTime start(DateTime month) => DateTime(month.year, month.month, startDay);

  /// First day after [month]'s period (exclusive end).
  DateTime endExclusive(DateTime month) =>
      DateTime(month.year, month.month + 1, startDay);

  /// Last day (inclusive) of [month]'s period.
  DateTime lastDay(DateTime month) =>
      endExclusive(month).subtract(const Duration(days: 1));

  bool contains(DateTime month, DateTime date) {
    final d = _dayOf(date);
    return !d.isBefore(start(month)) && d.isBefore(endExclusive(month));
  }

  int lengthInDays(DateTime month) =>
      _daysBetween(start(month), endExclusive(month));

  /// Days of [month]'s period that have started as of [now], counting today
  /// (0 for a future period, full length for a past one).
  int daysElapsed(DateTime month, DateTime now) {
    final today = _dayOf(now);
    final length = lengthInDays(month);
    if (today.isBefore(start(month))) return 0;
    if (!today.isBefore(endExclusive(month))) return length;
    return _daysBetween(start(month), today) + 1;
  }

  /// Active days left in [month]'s period including today: 0 for a past
  /// period, the full length for a future one.
  int daysRemaining(DateTime month, DateTime now) {
    final today = _dayOf(now);
    if (!today.isBefore(endExclusive(month))) return 0;
    if (today.isBefore(start(month))) return lengthInDays(month);
    return _daysBetween(today, endExclusive(month));
  }

  bool isCurrent(DateTime month, DateTime now) {
    final p = periodOf(now);
    return p.year == month.year && p.month == month.month;
  }

  bool isFuture(DateTime month, DateTime now) =>
      _dayOf(now).isBefore(start(month));

  /// "June 2026" for the calendar month, "25 Jun - 24 Jul 2026" otherwise.
  String label(DateTime month) {
    if (isCalendarMonth) return DateFormat('MMMM yyyy').format(month);
    final from = start(month);
    final to = lastDay(month);
    final fromText = DateFormat('d MMM').format(from);
    final toText = DateFormat('d MMM yyyy').format(to);
    return '$fromText - $toText';
  }

  // Calendar-day difference immune to DST (uses UTC dates).
  static int _daysBetween(DateTime a, DateTime b) {
    final ua = DateTime.utc(a.year, a.month, a.day);
    final ub = DateTime.utc(b.year, b.month, b.day);
    return ub.difference(ua).inDays;
  }

  @override
  bool operator ==(Object other) =>
      other is BudgetPeriod && other.startDay == startDay;

  @override
  int get hashCode => startDay.hashCode;
}
