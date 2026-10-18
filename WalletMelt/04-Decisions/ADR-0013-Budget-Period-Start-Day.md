---
type: adr
status: accepted
created: 2026-10-18
updated: 2026-10-18
domain: architecture
related:
  - "[[ADR-0008-Deterministic-Financial-Metrics-Engine]]"
  - "[[ADR-0012-Income-Schedules-and-Budget-Suggestion]]"
  - "[[Student-Market-Strategy]]"
---

# ADR-0013: Budget period start day ("my month starts on the 25th")

## Status
Accepted 2026-10-18. Owner chose: a single start day (no custom ranges yet) and regrouping of all history by the new start day.

## Context
Budgets, the daily allowance, Insights and History all assume a calendar month. People paid on the 25th, or receiving an allowance on a fixed day, budget from payday to payday. `selectedMonth` (a `DateTime(year, month)`) and `monthKey` (`yyyy-MM`) identify the period everywhere, and `monthly_budgets` / `category_budgets` are keyed by that string.

## Decision
1. **One setting**: `budgetPeriodStartDay`, integer 1 to 28, default 1 (calendar month, behaviour unchanged). Days 29 to 31 are not offered, so a period always starts on a real date in every month. Stored with the other settings (`WalletMeltSettings`), therefore included in the backup settings section.
2. **Period identity is unchanged**: a period is named after the month in which it **starts**. With start day 25, period `2026-06` runs 25 Jun 2026 to 24 Jul 2026 inclusive. Existing `selectedMonth`, `monthKey`, `monthly_budgets` and `category_budgets` rows keep their keys, so **no schema change and no data migration**.
3. **Pure helper** `BudgetPeriod(startDay)` in `lib/src/utils/budget_period.dart`: `periodOf(date)`, `start(month)`, `endExclusive(month)`, `contains(month, date)`, `lengthInDays(month)`, `daysElapsed(month, now)`, `daysRemaining(month, now)`, `label(month)`. `BudgetPeriod.calendar` (start day 1) reproduces today's results exactly.
4. **Regroup everything**: changing the start day re-buckets all history, budgets, Insights and the allowance by the new periods (past budgets keep their amount, applied to the shifted range). No data is rewritten.
5. **Plumbing**: analytics APIs take an optional `BudgetPeriod period` (default calendar) so existing tests and callers are unaffected; `AppState` owns the setting and passes it. The "current period" at app start is `periodOf(today)` (on 3 Jul with start day 25 the current period is `2026-06`).
6. **Display**: with start day 1 labels stay "June 2026"; otherwise "25 Jun - 24 Jul 2026".
7. **Income planning** (ADR-0012) counts incomes and schedule occurrences inside the selected period rather than the calendar month.
8. **Out of scope / unchanged**: yearly tax figures stay calendar-year based (the monthly tax figure on Insights follows the selected period); subscriptions, debts and essentials keep their own dates; custom date ranges and semesters are a possible later ADR; calendar-month sorting in raw exports is unchanged.

## Alternatives Considered
1. **Re-key budgets by period start date** (`2026-06-25`): needs a data migration and breaks backup compatibility. Rejected; naming by start month needs none.
2. **Apply only from now on**: mixed calendar and shifted history makes comparisons and previous-period deltas ambiguous. Rejected by the owner.
3. **Arbitrary ranges / semesters now**: much more UI and a new table. Deferred.

## Consequences
- **Positive**: Works for payday and fixed-day allowances with zero migration; default behaviour identical; helper is pure and fully testable.
- **Negative / Trade-offs**: A change of start day shifts historical numbers (explained in the settings copy); "previous period" comparisons use shifted ranges; the period name can look odd (period `2026-06` ends in July).
- **Neutral**: Settings schema gains one integer; backups written before this field restore with start day 1.

## Related Code
- `lib/src/utils/budget_period.dart`, `lib/src/types/settings.dart`
- `lib/src/analytics/spending_analytics.dart`, `financial_metrics_calculator.dart`, `income_planner.dart`
- `lib/src/state/app_state.dart`, budget / dashboard / history / insights screens

## Related Decisions
- [[ADR-0008-Deterministic-Financial-Metrics-Engine]]
- [[ADR-0012-Income-Schedules-and-Budget-Suggestion]]

## Implementation notes (2026-10-18)
- Setting stored in shared preferences (`settings.budgetPeriodStartDay`) and written to backups as `budget_period_start_day`; older backups restore as 1.
- `AppState.setBudgetPeriodStartDay` clamps to 1 to 28, clears the monthly-budget cache, moves the selected period to the one containing today and refreshes.
- History headers show the period label when the start day is not 1.
- Tests: `test/utils/budget_period_test.dart`, `test/analytics/budget_period_integration_test.dart`.
