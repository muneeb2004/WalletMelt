import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';
import '../utils/budget_period.dart';
import '../utils/recurrence.dart';
import '../types/debt.dart';
import '../types/expense.dart';
import '../types/subscription.dart';

/// Result container for Daily Spend Allowance calculations.
class DailyAllowanceResult {
  const DailyAllowanceResult({
    required this.dailyAllowance,
    required this.remainingBudget,
    required this.daysRemaining,
    required this.isCurrentMonth,
    required this.isOverBudget,
    required this.hasBudget,
    required this.totalBudget,
    required this.totalSpent,
  });

  /// The amount allowed to be spent per remaining day.
  /// Always 0.0 if over budget, if no budget is set, or if the month is in the past.
  final double dailyAllowance;

  /// The budget remaining (can be negative if over budget).
  final double? remainingBudget;

  /// Days remaining in the month (including today).
  final int daysRemaining;

  /// Whether the evaluated month is the current calendar month.
  final bool isCurrentMonth;

  /// True when a budget is set and spending exceeds it.
  final bool isOverBudget;

  /// True when a positive monthly budget has been defined.
  final bool hasBudget;

  /// The monthly budget limit amount (0.0 if not set).
  final double totalBudget;

  /// Total spending recorded for this month.
  final double totalSpent;
}

/// Result container for Budget Utilization metrics.
class BudgetUtilizationResult {
  const BudgetUtilizationResult({
    required this.hasBudget,
    required this.ratio,
    required this.percentage,
    required this.remaining,
    required this.isOverBudget,
    required this.overBudgetAmount,
    required this.progressColor,
  });

  final bool hasBudget;
  final double ratio;
  final double percentage;
  final double remaining;
  final bool isOverBudget;
  final double overBudgetAmount;
  final Color progressColor;
}

/// Result container for Debt and Obligation aggregations.
class DebtSummaryResult {
  const DebtSummaryResult({
    required this.receivables,
    required this.liabilities,
    required this.netPosition,
    required this.overdueAmount,
  });

  final double receivables;
  final double liabilities;
  final double netPosition;
  final double overdueAmount;
}

/// Canonical financial mathematical engine for WalletMelt.
///
/// Centralizes all financial metrics formulas to guarantee consistency across
/// Dashboard, Budget, Insights, Planning, and transparency menus.
class FinancialMetricsCalculator {
  FinancialMetricsCalculator._();

  /// Calculates the active days remaining in [month].
  ///
  /// Mathematical Specification:
  /// - Past months: 0 days remaining.
  /// - Current month: `lastDayOfMonth - now.day + 1`.
  ///   Today is an active spending day and is therefore included (+1).
  ///   For example, on day 13 of a 30-day month: 30 - 13 + 1 = 18 days remaining.
  ///   On the final day (day 30): 30 - 30 + 1 = 1 day remaining.
  /// - Future months: Total days in that month (e.g. 30 or 31).
  ///
  /// With a non-default [period] (ADR-0013) the same rules apply to the
  /// period's first and last day instead of the calendar month.
  static int calculateDaysRemainingInMonth(DateTime month,
      [DateTime? now, BudgetPeriod period = BudgetPeriod.calendar]) {
    final referenceNow = now ?? DateTime.now();
    return period.daysRemaining(month, referenceNow);
  }

  /// Calculates Daily Spend Allowance for [month].
  ///
  /// Formula:
  ///   $$\text{Daily Allowance} = \frac{\text{Remaining Monthly Budget}}{\text{Days Remaining (including today)}}$$
  ///
  /// Rules:
  /// - If [monthlyBudget] is null or <= 0: daily allowance is 0.0.
  /// - If [remainingBudget] <= 0: over budget, allowance is 0.0.
  /// - Only applicable to the current active month (past months are closed).
  static DailyAllowanceResult calculateDailySpendAllowance({
    required double? monthlyBudget,
    required double totalSpent,
    required DateTime month,
    DateTime? now,
    BudgetPeriod period = BudgetPeriod.calendar,
  }) {
    final referenceNow = now ?? DateTime.now();
    final isCurrentMonth = period.isCurrent(month, referenceNow);

    final hasBudget = monthlyBudget != null && monthlyBudget > 0;
    final totalBudget = monthlyBudget ?? 0.0;
    final remainingBudget = hasBudget ? (totalBudget - totalSpent) : null;
    final isOverBudget = hasBudget && (remainingBudget ?? 0.0) < 0;

    final daysRemaining =
        calculateDaysRemainingInMonth(month, referenceNow, period);

    double allowance = 0.0;
    if (isCurrentMonth && hasBudget && !isOverBudget && daysRemaining > 0) {
      allowance = (remainingBudget! / daysRemaining);
    }

    return DailyAllowanceResult(
      dailyAllowance: allowance,
      remainingBudget: remainingBudget,
      daysRemaining: daysRemaining,
      isCurrentMonth: isCurrentMonth,
      isOverBudget: isOverBudget,
      hasBudget: hasBudget,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
    );
  }

  /// Computes budget progress, ratio, over-budget indicators, and UI color.
  static BudgetUtilizationResult calculateBudgetUtilization({
    required double? monthlyBudget,
    required double totalSpent,
  }) {
    final hasBudget = monthlyBudget != null && monthlyBudget > 0;
    final totalBudget = monthlyBudget ?? 0.0;
    final remaining = hasBudget ? (totalBudget - totalSpent) : 0.0;
    final isOverBudget = hasBudget && remaining < 0;
    final ratio = hasBudget ? (totalSpent / totalBudget) : 0.0;
    final percentage = ratio * 100;
    final progressColor = budgetProgressColor(ratio);

    return BudgetUtilizationResult(
      hasBudget: hasBudget,
      ratio: ratio,
      percentage: percentage,
      remaining: remaining,
      isOverBudget: isOverBudget,
      overBudgetAmount: isOverBudget ? -remaining : 0.0,
      progressColor: progressColor,
    );
  }

  /// Calculates Month-over-Month percentage delta.
  ///
  /// Formula:
  ///   $$\text{Delta} = \frac{\text{Current Total} - \text{Previous Total}}{\text{Previous Total}} \times 100$$
  /// Returns `null` if [previousTotal] is null or zero.
  static double? calculateMonthOverMonthDelta(
    double currentTotal,
    double? previousTotal,
  ) {
    if (previousTotal == null || previousTotal == 0) return null;
    return ((currentTotal - previousTotal) / previousTotal) * 100;
  }

  /// Calculates Debt receivables, liabilities, net position, and overdue amounts.
  static DebtSummaryResult calculateDebtSummary(
    List<DebtRecord> debts, [
    DateTime? now,
  ]) {
    final referenceNow = now ?? DateTime.now();
    final todayIso = referenceNow.toIso8601String().substring(0, 10);

    double receivables = 0.0;
    double liabilities = 0.0;
    double overdue = 0.0;

    for (final debt in debts) {
      if (debt.isSettled) continue;

      final isReceivable =
          debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven;
      if (isReceivable) {
        receivables += debt.remainingAmount;
      } else {
        liabilities += debt.remainingAmount;
      }

      if (debt.dueDate != null && debt.dueDate!.compareTo(todayIso) < 0) {
        overdue += debt.remainingAmount;
      }
    }

    return DebtSummaryResult(
      receivables: receivables,
      liabilities: liabilities,
      netPosition: receivables - liabilities,
      overdueAmount: overdue,
    );
  }

  /// Normalizes a subscription's billing cycle to monthly and annual equivalents.
  static double normalizeSubscriptionToMonthly(Subscription sub) {
    final cost = sub.amount + (sub.taxAmount ?? 0.0);
    return monthlyEquivalent(sub.billingCycle, cost);
  }

  /// Computes tax metrics from a list of expenses for a specific month and year.
  static Map<String, double> calculateTaxMetrics({
    required List<Expense> expenses,
    required int year,
    required int month,
  }) {
    double monthlyTax = 0.0;
    double yearlyTax = 0.0;
    double taxableSpend = 0.0;
    double nonTaxableSpend = 0.0;

    for (final exp in expenses) {
      if (exp.deletedAt != null) continue;

      DateTime expDate;
      try {
        expDate = DateTime.parse(exp.date);
      } catch (_) {
        continue;
      }

      final isTargetYear = expDate.year == year;
      final isTargetMonth = isTargetYear && expDate.month == month;

      if (isTargetMonth) {
        if (exp.taxAmount != null && exp.taxAmount! > 0) {
          monthlyTax += exp.taxAmount!;
          taxableSpend += exp.subtotalAmount ?? (exp.amount - exp.taxAmount!);
        } else {
          nonTaxableSpend += exp.amount;
        }
      }

      if (isTargetYear && exp.taxAmount != null && exp.taxAmount! > 0) {
        yearlyTax += exp.taxAmount!;
      }
    }

    final effectiveTaxRate =
        taxableSpend > 0 ? (monthlyTax / taxableSpend) * 100 : 0.0;

    return {
      'monthlyTax': monthlyTax,
      'yearlyTax': yearlyTax,
      'taxableSpend': taxableSpend,
      'nonTaxableSpend': nonTaxableSpend,
      'effectiveTaxRate': effectiveTaxRate,
    };
  }
}
