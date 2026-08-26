import '../types/expense.dart';

/// Aggregated metrics for a single merchant key within the selected month.
class MerchantAggregate {
  const MerchantAggregate({
    required this.merchantKey,
    required this.displayName,
    required this.netAmount,
    required this.positiveAmount,
    required this.positiveTransactionCount,
    required this.refundCount,
    required this.categoryIds,
  });

  final String merchantKey;
  final String displayName;
  final double netAmount;
  final double positiveAmount;
  final int positiveTransactionCount;
  final int refundCount;

  /// Categories associated strictly with positive purchases (`amount > 0`).
  final Set<String> categoryIds;
}

/// A complete, single-pass immutable snapshot of spending aggregates
/// across current and previous periods.
class SpendingAnalyticsSnapshot {
  const SpendingAnalyticsSnapshot({
    required this.selectedMonth,
    required this.now,
    required this.snapshotGeneratedAt,
    required this.currency,
    required this.isFutureMonth,
    required this.currentTotal,
    required this.previousTotal,
    required this.currentPositiveTotal,
    required this.previousPositiveTotal,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.currentByCategory,
    required this.previousByCategory,
    required this.currentPositiveCountByCategory,
    required this.currentRefundCountByCategory,
    required this.currentMerchants,
    required this.currentPositiveCount,
    required this.previousPositiveCount,
    required this.currentRefundCount,
    required this.previousRefundCount,
    required this.currentExpenses,
    required this.previousExpenses,
  });

  final DateTime selectedMonth;
  final DateTime now;
  final DateTime snapshotGeneratedAt;
  final String currency;
  final bool isFutureMonth;

  /// Net spending (`sum(amount)`) for selected month through today.
  final double currentTotal;

  /// Net spending (`sum(amount)`) for previous month.
  final double previousTotal;

  /// Positive spending (`sum(amount)` where `amount > 0`) for selected month through today.
  final double currentPositiveTotal;

  /// Positive spending for previous month.
  final double previousPositiveTotal;

  /// Days elapsed in the selected month (calendar-day model).
  final int daysElapsed;

  /// Total days in the selected month.
  final int daysInMonth;

  /// Category ID -> Net spend for selected month.
  final Map<String, double> currentByCategory;

  /// Category ID -> Net spend for previous month.
  final Map<String, double> previousByCategory;

  /// Category ID -> Count of positive transactions.
  final Map<String, int> currentPositiveCountByCategory;

  /// Category ID -> Count of refunds.
  final Map<String, int> currentRefundCountByCategory;

  /// Merchant Key -> Merchant aggregate for selected month.
  final Map<String, MerchantAggregate> currentMerchants;

  /// Total count of positive transactions (`amount > 0`) in selected month.
  final int currentPositiveCount;

  /// Total count of positive transactions in previous month.
  final int previousPositiveCount;

  /// Total count of refunds (`amount < 0`) in selected month.
  final int currentRefundCount;

  /// Total count of refunds in previous month.
  final int previousRefundCount;

  /// Active expenses in selected month occurring on or before `now`.
  final List<Expense> currentExpenses;

  /// Active expenses in previous month.
  final List<Expense> previousExpenses;

  /// Average positive transaction amount in selected month.
  double get currentAvgTransaction =>
      currentPositiveCount > 0 ? currentPositiveTotal / currentPositiveCount : 0.0;

  /// Average positive transaction amount in previous month.
  double get previousAvgTransaction =>
      previousPositiveCount > 0 ? previousPositiveTotal / previousPositiveCount : 0.0;
}
