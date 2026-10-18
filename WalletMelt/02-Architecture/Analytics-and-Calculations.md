---
type: architecture
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-18
domain: architecture
related:
  - "[[Product-Requirements]]"
  - "[[ADR-0008-Deterministic-Financial-Metrics-Engine]]"
---

# Analytics and Calculations

## 1. Deterministic Financial Mathematical Engine
All financial metrics are calculated via [`FinancialMetricsCalculator`](file:///d:/TechProjects/WalletMelt/lib/src/analytics/financial_metrics_calculator.dart) to guarantee mathematical consistency across Dashboard, Budget, Planning, and Settings screens.

### Core Mathematical Formulations:

1. **Days Remaining in Month ($D$)**:
   $$\text{Days Remaining} = \text{Total Days in Month} - \text{Current Day} + 1$$
   *(The $+1$ ensures the active calendar day is included, preventing artificial allowance compression).*

2. **Daily Spend Allowance ($A$)**:
   $$A = \begin{cases} \frac{\text{Remaining Budget}}{D} & \text{if Remaining Budget} > 0 \text{ and } D > 0 \\ 0.00 & \text{if Over Budget or No Budget Set} \end{cases}$$

3. **Budget Utilization Percentage ($U$)**:
   $$U = \left( \frac{\text{Total Month Spent}}{\text{Monthly Budget}} \right) \times 100\%$$
   - $\le 70\%$: Healthy (Positive Green)
   - $70\% - 90\%$: Caution (Warning Orange)
   - $> 90\%$: Danger (Danger Red)
   - $> 100\%$: Over Budget Flag

4. **Spending Velocity & Daily Pace**:
   $$\text{Daily Pace} = \frac{\text{Total Positive Spend}}{\text{Days Elapsed}}$$
   $$\text{Projected Total Spend} = \text{Daily Pace} \times \text{Total Days in Month}$$

5. **Debt & Obligations Position**:
   $$\text{Net Position} = \sum \text{Receivables (Owed To Me)} - \sum \text{Liabilities (I Owe)}$$

6. **Subscription Monthly Normalization**:
   Converts weekly ($\times 52 / 12$), bi-weekly ($\times 26 / 12$), quarterly ($/ 3$), and annual ($/ 12$) commitments into precise 30-day monthly burn rates.

## Subscription Renewal Dates (changed 2026-10-15)
`Subscription.calculateNextRenewalDate` advances month-based cycles (monthly 1, quarterly 3, semi-annual 6, annual 12 months) from the **anchor day** taken from `startDate`, clamped to the last day of the target month. Jan 31 -> Feb 28/29 -> Mar 31 (no permanent drift, no skipped February). `custom_N` adds N calendar days via `DateTime(y, m, d + N)` (no DST hour shift); `N <= 0` falls back to 30. Renewals are saved **atomically per subscription** (`DriftSubscriptionRepository.applyRenewals`: all renewal expenses + the advanced date in one transaction) and concurrent runs share one in-flight Future. Regression tests: `test/subscription_renewal_test.dart`.

## Account balance (2026-10-17, [[ADR-0011-Accounts-Derived-Balance-and-Transfers]])
`balance = openingBalance - expenseOutflow + movementNet + incomeInflow + debtNet`, in integer minor units (`BalanceCalculator`, `lib/src/analytics/balance_calculator.dart`).
- `expenseOutflow` sums non-deleted expenses with `accountId = account`, `expense.currency = account.currency` and `expense.date >= account.openingDate` (uses `amountMinorUnits`, falling back to `ROUND(amount * 100)` for legacy rows).
- `movementNet` sums non-deleted `account_movements` dated on/after `openingDate` (signed: transfer out and negative adjustments reduce it).
- Totals are one figure per currency over accounts that are included, not archived and not deleted; there is no FX conversion.
- Reconcile writes one `adjustment` of `actual - current`; history is never rewritten. Transfers and adjustments are not spending: budgets, daily allowance and Insights read only `Expenses` and are unchanged.
- Minor units use the existing fixed exponent 2 (`toMinorUnits`), consistent with every stored `*MinorUnits` row.

## Income planning (2026-10-17, [[ADR-0012-Income-Schedules-and-Budget-Suggestion]])
- `incomeInflow` sums non-deleted `incomes` with `accountId = account`, same currency, `date >= openingDate`. Income with no account affects no balance.
- `IncomePlanner` (`lib/src/analytics/income_planner.dart`, pure): **expected income for a month** = received incomes dated in the month + every active schedule occurrence in the month counted from the schedule's current `nextDueDate` (an overdue, unconfirmed occurrence still counts), per currency.
- **Suggested budget** (advisory, major units) = `expectedIncome - sum(monthly subscriptions) - sum(monthly essentials)`, floored at 0, null when no income is expected. Essentials' monthly equivalent: weekly x 52/12, quarterly /3, yearly /12, `custom_N` x 30/N. The user's own monthly budget is never overwritten.
- Recurrence arithmetic lives in `lib/src/utils/recurrence.dart` (`advanceByCycle`), shared with subscriptions. Weekly now advances 7 days (subscriptions previously treated an unknown/weekly cycle as monthly).

## Budget periods (2026-10-18, [[ADR-0013-Budget-Period-Start-Day]])
Everything that was "the calendar month" is now "the budget period": `SpendingAnalytics.buildSnapshot`, `FinancialMetricsCalculator.calculateDaysRemainingInMonth` / `calculateDailySpendAllowance`, `IncomePlanner.expectedForMonth`, `groupExpensesByMonth` and AppState's current-period expense filter take a `BudgetPeriod` (default `BudgetPeriod.calendar`, identical to the old behaviour).
- Period named by start month: with start day D, period `YYYY-MM` = D of that month to D-1 of the next month, inclusive.
- Days elapsed counts from the period start including today; days remaining counts to the last day including today (never 0 inside the current period). Daily allowance = remaining budget / days remaining.
- Tax metrics by calendar year stay calendar-based; the monthly tax figure on the Insights screen follows the selected period.

## Debt cash flow (2026-10-18, [[ADR-0014-Debts-and-Subscriptions-Move-Account-Balances]])
`debtNet` covers debts linked to the account, in the account currency, dated on or after its opening date. Principal at creation: `loanGiven` = minus, `loanTaken` = plus, `owedToMe` and `iOwe` = zero. Repayments: plus for `owedToMe` and `loanGiven`, minus for `iOwe` and `loanTaken` (`ROUND(amount * 100)`; repayments have no minor-unit column). Subscription renewals are ordinary expenses carrying the subscription's account when it is active and in the same currency. Spending analytics are unchanged.

## Savings goals (2026-10-18, [[ADR-0015-Savings-Goals-Set-Aside-in-Accounts]])
`GoalPlanner` (`lib/src/analytics/goal_planner.dart`, pure): `saved(goal)` = sum of non-deleted contributions; `reserved(account)` = sum of saved over active goals (achieved and archived reserve nothing, negative sums floor at 0); `freeToSpend = balance - reserved` (may be negative); free totals use the same inclusion rules as total balance. `monthsLeft` counts whole calendar months to the target date (minimum 1 while in the future, 0 once passed); `monthlyPace = ceil(remaining / monthsLeft)`, null without a date, once reached or after the date. Account balance and spending analytics are unchanged.
