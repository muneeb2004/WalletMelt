import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/financial_metrics_calculator.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/debt.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/subscription.dart';

void main() {
  group('FinancialMetricsCalculator - Days Remaining Math', () {
    test('calculates correct days remaining at start of month (Sept 1 of 30 days)', () {
      final month = DateTime(2026, 9, 1);
      final now = DateTime(2026, 9, 1);
      final days = FinancialMetricsCalculator.calculateDaysRemainingInMonth(month, now);
      // 30 - 1 + 1 = 30 days
      expect(days, equals(30));
    });

    test('calculates correct days remaining mid-month (Sept 13 of 30 days)', () {
      final month = DateTime(2026, 9, 1);
      final now = DateTime(2026, 9, 13);
      final days = FinancialMetricsCalculator.calculateDaysRemainingInMonth(month, now);
      // 30 - 13 + 1 = 18 days (including today)
      expect(days, equals(18));
    });

    test('calculates exactly 1 day remaining on the final calendar day (Sept 30 of 30 days)', () {
      final month = DateTime(2026, 9, 1);
      final now = DateTime(2026, 9, 30);
      final days = FinancialMetricsCalculator.calculateDaysRemainingInMonth(month, now);
      // 30 - 30 + 1 = 1 day (today is the 1 day left)
      expect(days, equals(1));
    });

    test('handles leap year February correctly (Feb 28 of 2024 leap year)', () {
      final month = DateTime(2024, 2, 1);
      final now = DateTime(2024, 2, 28);
      final days = FinancialMetricsCalculator.calculateDaysRemainingInMonth(month, now);
      // 29 - 28 + 1 = 2 days
      expect(days, equals(2));
    });

    test('returns 0 days remaining for past months', () {
      final pastMonth = DateTime(2026, 8, 1);
      final now = DateTime(2026, 9, 13);
      final days = FinancialMetricsCalculator.calculateDaysRemainingInMonth(pastMonth, now);
      expect(days, equals(0));
    });

    test('returns total days for future months', () {
      final futureMonth = DateTime(2026, 10, 1); // 31 days
      final now = DateTime(2026, 9, 13);
      final days = FinancialMetricsCalculator.calculateDaysRemainingInMonth(futureMonth, now);
      expect(days, equals(31));
    });
  });

  group('FinancialMetricsCalculator - Daily Spend Allowance', () {
    test('calculates daily allowance accurately when within budget', () {
      final month = DateTime(2026, 9, 1);
      final now = DateTime(2026, 9, 13); // 18 days remaining
      final result = FinancialMetricsCalculator.calculateDailySpendAllowance(
        monthlyBudget: 36000.0,
        totalSpent: 18000.0,
        month: month,
        now: now,
      );

      expect(result.hasBudget, isTrue);
      expect(result.isCurrentMonth, isTrue);
      expect(result.isOverBudget, isFalse);
      expect(result.remainingBudget, equals(18000.0));
      expect(result.daysRemaining, equals(18));
      // 18000 / 18 = 1000 per day
      expect(result.dailyAllowance, equals(1000.0));
    });

    test('returns 0.0 allowance and isOverBudget true when spend exceeds budget', () {
      final month = DateTime(2026, 9, 1);
      final now = DateTime(2026, 9, 13);
      final result = FinancialMetricsCalculator.calculateDailySpendAllowance(
        monthlyBudget: 10000.0,
        totalSpent: 12500.0,
        month: month,
        now: now,
      );

      expect(result.hasBudget, isTrue);
      expect(result.isOverBudget, isTrue);
      expect(result.remainingBudget, equals(-2500.0));
      expect(result.dailyAllowance, equals(0.0));
    });

    test('returns 0.0 allowance when spend equals budget', () {
      final month = DateTime(2026, 9, 1);
      final now = DateTime(2026, 9, 13);
      final result = FinancialMetricsCalculator.calculateDailySpendAllowance(
        monthlyBudget: 10000.0,
        totalSpent: 10000.0,
        month: month,
        now: now,
      );

      expect(result.remainingBudget, equals(0.0));
      expect(result.dailyAllowance, equals(0.0));
      expect(result.isOverBudget, isFalse);
    });

    test('returns 0.0 allowance when monthly budget is null or 0', () {
      final month = DateTime(2026, 9, 1);
      final now = DateTime(2026, 9, 13);
      final resultNull = FinancialMetricsCalculator.calculateDailySpendAllowance(
        monthlyBudget: null,
        totalSpent: 5000.0,
        month: month,
        now: now,
      );
      expect(resultNull.hasBudget, isFalse);
      expect(resultNull.dailyAllowance, equals(0.0));

      final resultZero = FinancialMetricsCalculator.calculateDailySpendAllowance(
        monthlyBudget: 0.0,
        totalSpent: 5000.0,
        month: month,
        now: now,
      );
      expect(resultZero.hasBudget, isFalse);
      expect(resultZero.dailyAllowance, equals(0.0));
    });

    test('returns 0.0 allowance for past months', () {
      final pastMonth = DateTime(2026, 8, 1);
      final now = DateTime(2026, 9, 13);
      final result = FinancialMetricsCalculator.calculateDailySpendAllowance(
        monthlyBudget: 20000.0,
        totalSpent: 15000.0,
        month: pastMonth,
        now: now,
      );
      expect(result.isCurrentMonth, isFalse);
      expect(result.dailyAllowance, equals(0.0));
    });
  });

  group('FinancialMetricsCalculator - Budget Utilization', () {
    test('computes healthy ratio, percentage, and green color when <= 70%', () {
      final util = FinancialMetricsCalculator.calculateBudgetUtilization(
        monthlyBudget: 10000.0,
        totalSpent: 5000.0,
      );
      expect(util.hasBudget, isTrue);
      expect(util.ratio, equals(0.5));
      expect(util.percentage, equals(50.0));
      expect(util.remaining, equals(5000.0));
      expect(util.isOverBudget, isFalse);
      expect(util.progressColor, equals(WalletMeltColors.positive));
    });

    test('computes warning color when between 70% and 90%', () {
      final util = FinancialMetricsCalculator.calculateBudgetUtilization(
        monthlyBudget: 10000.0,
        totalSpent: 8000.0,
      );
      expect(util.ratio, equals(0.8));
      expect(util.isOverBudget, isFalse);
      expect(util.progressColor, equals(WalletMeltColors.warning));
    });

    test('computes danger color and overBudgetAmount when > 100%', () {
      final util = FinancialMetricsCalculator.calculateBudgetUtilization(
        monthlyBudget: 10000.0,
        totalSpent: 13000.0,
      );
      expect(util.ratio, equals(1.3));
      expect(util.isOverBudget, isTrue);
      expect(util.overBudgetAmount, equals(3000.0));
      expect(util.progressColor, equals(WalletMeltColors.danger));
    });
  });

  group('FinancialMetricsCalculator - Debt Summary', () {
    test('aggregates receivables, liabilities, net position, and overdue amounts', () {
      final now = DateTime(2026, 9, 13);
      final debts = <DebtRecord>[
        const DebtRecord(
          id: 'd1',
          personName: 'Alice',
          principalAmount: 5000.0,
          remainingAmount: 5000.0,
          currency: 'PKR',
          type: DebtType.owedToMe, // Receivable
          status: DebtStatus.active,
          createdAt: '2026-09-01T10:00:00.000Z',
          dueDate: '2026-09-10', // Overdue (< Sept 13)
        ),
        const DebtRecord(
          id: 'd2',
          personName: 'Bob',
          principalAmount: 2000.0,
          remainingAmount: 2000.0,
          currency: 'PKR',
          type: DebtType.owedToMe, // Receivable
          status: DebtStatus.active,
          createdAt: '2026-09-05T10:00:00.000Z',
          dueDate: '2026-09-20', // Not overdue
        ),
        const DebtRecord(
          id: 'd3',
          personName: 'Charlie',
          principalAmount: 3000.0,
          remainingAmount: 3000.0,
          currency: 'PKR',
          type: DebtType.iOwe, // Liability
          status: DebtStatus.active,
          createdAt: '2026-09-02T10:00:00.000Z',
          dueDate: '2026-09-12', // Overdue
        ),
        const DebtRecord(
          id: 'd4',
          personName: 'David',
          principalAmount: 10000.0,
          remainingAmount: 10000.0,
          currency: 'PKR',
          type: DebtType.owedToMe,
          status: DebtStatus.settled, // Settled - should be ignored
          createdAt: '2026-08-01T10:00:00.000Z',
        ),
      ];

      final summary = FinancialMetricsCalculator.calculateDebtSummary(debts, now);
      expect(summary.receivables, equals(7000.0)); // 5000 + 2000
      expect(summary.liabilities, equals(3000.0));
      expect(summary.netPosition, equals(4000.0)); // 7000 - 3000
      expect(summary.overdueAmount, equals(8000.0)); // 5000 + 3000
    });
  });

  group('FinancialMetricsCalculator - Subscriptions & Taxes', () {
    test('normalizes subscriptions accurately across intervals', () {
      final monthly = const Subscription(
        id: 's1',
        name: 'Netflix',
        categoryId: 'cat1',
        amount: 1200.0,
        currency: 'PKR',
        billingCycle: 'monthly',
        status: SubscriptionStatus.active,
        startDate: '2026-01-01',
        nextOccurrenceDate: '2026-02-01',
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      );
      expect(FinancialMetricsCalculator.normalizeSubscriptionToMonthly(monthly), equals(1200.0));

      final annual = const Subscription(
        id: 's2',
        name: 'Amazon Prime',
        categoryId: 'cat2',
        amount: 12000.0,
        currency: 'PKR',
        billingCycle: 'annual',
        status: SubscriptionStatus.active,
        startDate: '2026-01-01',
        nextOccurrenceDate: '2027-01-01',
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      );
      expect(FinancialMetricsCalculator.normalizeSubscriptionToMonthly(annual), equals(1000.0));

      final quarterly = const Subscription(
        id: 's3',
        name: 'Cloud Storage',
        categoryId: 'cat3',
        amount: 3000.0,
        currency: 'PKR',
        billingCycle: 'quarterly',
        status: SubscriptionStatus.active,
        startDate: '2026-01-01',
        nextOccurrenceDate: '2026-04-01',
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      );
      expect(FinancialMetricsCalculator.normalizeSubscriptionToMonthly(quarterly), equals(1000.0));
    });

    test('calculates tax metrics and effective rate', () {
      final expenses = <Expense>[
        const Expense(
          id: 'e1',
          title: 'Groceries',
          amount: 1150.0,
          currency: 'PKR',
          subtotalAmount: 1000.0,
          taxAmount: 150.0,
          categoryId: 'c1',
          isRecurring: false,
          date: '2026-09-05T12:00:00.000Z',
          createdAt: '2026-09-05T12:00:00.000Z',
          updatedAt: '2026-09-05T12:00:00.000Z',
        ),
        const Expense(
          id: 'e2',
          title: 'Transport',
          amount: 500.0,
          currency: 'PKR',
          categoryId: 'c2',
          isRecurring: false,
          date: '2026-09-08T12:00:00.000Z',
          createdAt: '2026-09-08T12:00:00.000Z',
          updatedAt: '2026-09-08T12:00:00.000Z',
        ),
      ];

      final taxes = FinancialMetricsCalculator.calculateTaxMetrics(
        expenses: expenses,
        year: 2026,
        month: 9,
      );

      expect(taxes['monthlyTax'], equals(150.0));
      expect(taxes['taxableSpend'], equals(1000.0));
      expect(taxes['nonTaxableSpend'], equals(500.0));
      expect(taxes['effectiveTaxRate'], equals(15.0)); // 150 / 1000 * 100 = 15%
    });
  });
}
