import '../types/essential_expense.dart';
import '../types/income.dart';
import '../types/subscription.dart';
import '../utils/recurrence.dart';
import 'financial_metrics_calculator.dart';

/// Pure planning maths for ADR-0012. No I/O, deterministic.
class IncomePlanner {
  const IncomePlanner._();

  /// Expected income (minor units) for [currency] in the calendar month of
  /// [month]: received incomes dated in the month plus every active schedule
  /// occurrence dated in the month at or after the schedule's `nextDueDate`
  /// (an overdue, unconfirmed occurrence still counts).
  static int expectedForMonth({
    required DateTime month,
    required String currency,
    required Iterable<Income> received,
    required Iterable<IncomeSchedule> schedules,
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    var total = 0;
    for (final income in received) {
      if (income.deletedAt != null || income.currency != currency) continue;
      final date = DateTime.tryParse(income.date);
      if (date != null && !date.isBefore(start) && date.isBefore(end)) {
        total += income.amountMinorUnits;
      }
    }
    for (final s in schedules) {
      if (!s.isActive || s.deletedAt != null || s.currency != currency) continue;
      total += s.amountMinorUnits * occurrencesInMonth(s, start, end);
    }
    return total;
  }

  /// Number of occurrences of [schedule] in [start, end) counted from its
  /// current `nextDueDate`. Capped to avoid runaway loops on bad data.
  static int occurrencesInMonth(
      IncomeSchedule schedule, DateTime start, DateTime end) {
    var cursor = DateTime.tryParse(schedule.nextDueDate);
    if (cursor == null) return 0;
    var count = 0;
    for (var i = 0; i < 400 && cursor!.isBefore(end); i++) {
      if (!cursor.isBefore(start)) count++;
      final next = advanceByCycle(schedule.cycle, cursor, schedule.anchorDay);
      if (!next.isAfter(cursor)) break;
      cursor = next;
    }
    return count;
  }

  /// Monthly equivalent of an essential template, in major units.
  static double essentialMonthly(EssentialExpenseTemplate t) {
    final cycle = t.frequency.toLowerCase().trim();
    final cost = t.expectedAmount;
    return switch (cycle) {
      'monthly' => cost,
      'weekly' => cost * (52.0 / 12.0),
      'quarterly' => cost / 3.0,
      'yearly' || 'annual' => cost / 12.0,
      _ when cycle.startsWith('custom_') => () {
          final days = int.tryParse(cycle.split('_').last) ?? 30;
          return days > 0 ? cost * (30.0 / days) : cost;
        }(),
      _ => cost,
    };
  }

  /// Advisory monthly budget in major units:
  /// `expectedIncome - monthly subscriptions - monthly essentials`, floored at 0.
  /// Returns null when no income is expected (nothing to base a suggestion on).
  static double? suggestedBudget({
    required int expectedIncomeMinorUnits,
    required Iterable<Subscription> subscriptions,
    required Iterable<EssentialExpenseTemplate> essentials,
  }) {
    if (expectedIncomeMinorUnits <= 0) return null;
    var committed = 0.0;
    for (final sub in subscriptions) {
      if (sub.status != SubscriptionStatus.active || sub.deletedAt != null) {
        continue;
      }
      committed += FinancialMetricsCalculator.normalizeSubscriptionToMonthly(sub);
    }
    for (final t in essentials) {
      if (!t.isActive || t.deletedAt != null) continue;
      committed += essentialMonthly(t);
    }
    final suggestion = expectedIncomeMinorUnits / 100.0 - committed;
    return suggestion < 0 ? 0 : suggestion;
  }
}
