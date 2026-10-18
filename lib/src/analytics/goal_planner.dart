import '../types/account.dart';
import '../types/savings_goal.dart';

/// Pure savings-goal maths for ADR-0015. No I/O, deterministic.
class GoalPlanner {
  const GoalPlanner._();

  /// Money set aside per account: the saved amount of every active goal.
  /// Achieved and archived goals reserve nothing. Negative sums (data errors)
  /// are floored at zero.
  static Map<String, int> reservedByAccount(Iterable<GoalProgress> progress) {
    final reserved = <String, int>{};
    for (final p in progress) {
      if (!p.goal.isActive || p.goal.deletedAt != null) continue;
      reserved[p.goal.accountId] =
          (reserved[p.goal.accountId] ?? 0) + p.savedMinorUnits;
    }
    return {for (final e in reserved.entries) e.key: e.value < 0 ? 0 : e.value};
  }

  /// Balance minus what is set aside. May be negative (over-reserved).
  static int freeToSpend(int balanceMinorUnits, int reservedMinorUnits) =>
      balanceMinorUnits - reservedMinorUnits;

  /// Free-to-spend totals per currency over accounts that count toward the
  /// total balance (included, not archived, not deleted).
  static List<CurrencyTotal> freeTotalsByCurrency(
    Iterable<AccountBalance> balances,
    Map<String, int> reservedByAccount,
  ) {
    final sums = <String, int>{};
    for (final b in balances) {
      final a = b.account;
      if (!a.includeInTotal || a.isArchived || a.deletedAt != null) continue;
      sums[a.currency] = (sums[a.currency] ?? 0) +
          freeToSpend(b.balanceMinorUnits, reservedByAccount[a.id] ?? 0);
    }
    final currencies = sums.keys.toList()..sort();
    return [
      for (final c in currencies) CurrencyTotal(currency: c, minorUnits: sums[c]!),
    ];
  }

  /// Whole calendar months from [now] to [targetDate], at least 1 while the
  /// date is in the future; 0 when the date has passed or is today.
  static int monthsLeft(DateTime now, DateTime targetDate) {
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(targetDate.year, targetDate.month, targetDate.day);
    if (!target.isAfter(today)) return 0;
    final months =
        (target.year - today.year) * 12 + (target.month - today.month);
    final adjusted = target.day < today.day ? months - 1 : months;
    return adjusted < 1 ? 1 : adjusted;
  }

  /// Advisory amount to set aside per month to reach the target by its date,
  /// rounded up to a whole minor unit. Null when there is no date, the goal is
  /// already reached, or the date has passed.
  static int? monthlyPaceMinorUnits({
    required GoalProgress progress,
    required DateTime now,
  }) {
    final raw = progress.goal.targetDate;
    if (raw == null || progress.isReached) return null;
    final target = DateTime.tryParse(raw);
    if (target == null) return null;
    final months = monthsLeft(now, target);
    if (months == 0) return null;
    final remaining = progress.remainingMinorUnits;
    return (remaining + months - 1) ~/ months;
  }
}
