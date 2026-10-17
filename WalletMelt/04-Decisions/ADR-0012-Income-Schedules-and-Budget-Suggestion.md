---
type: adr
status: accepted
created: 2026-10-17
updated: 2026-10-17
domain: architecture
related:
  - "[[ADR-0011-Accounts-Derived-Balance-and-Transfers]]"
  - "[[Balance-Income-and-Auto-Capture-Exploration]]"
  - "[[Student-Market-Strategy]]"
  - "[[ADR-0008-Deterministic-Financial-Metrics-Engine]]"
---

# ADR-0012: Income, recurring income schedules and budget suggestion

## Status
Accepted 2026-10-17 (Phase 2 of [[Balance-Income-and-Auto-Capture-Exploration]]). Pay-cycle budgets are explicitly **deferred** (see Decision 8).

## Context
Phase 1 ([[ADR-0011-Accounts-Derived-Balance-and-Transfers]]) gives a derived balance but money can only leave it. Users asked to update the balance when salary arrives and to plan monthly spend and limits. Students have irregular inflows (allowance, stipend), so receipt must be confirmed by the user, not assumed.

## Decision
1. **`incomes` table** (schema v11): `id`, `accountId` (nullable FK, RESTRICT), `scheduleId` (nullable, set when confirmed from a schedule), `title`, `source` (`salary|allowance|scholarship|freelance|gift|other`), `amountMinorUnits` (> 0), `currency`, `date`, `notes`, `createdAt`, `updatedAt`, `deletedAt` (soft delete). Income is a fact that was received.
2. **`income_schedules` table**: `id`, `title`, `source`, `amountMinorUnits`, `currency`, `accountId` (nullable FK, RESTRICT), `cycle` (same vocabulary as subscriptions: `weekly`, `monthly`, `quarterly`, `semi_annual`, `annual`, `custom_N`), `startDate` (anchor day), `nextDueDate`, `status` (`active|paused`), timestamps, `deletedAt`. A schedule is an expectation and never changes a balance by itself.
3. **Never auto-post.** When `nextDueDate <= today` the Dashboard shows a prompt per due schedule: **Received** (opens a pre-filled confirmation where the amount and date can be edited, creates an `incomes` row with `scheduleId`, advances `nextDueDate`) or **Skip** (advances only). Catch-up is one prompt at a time, oldest first.
4. **Balance**: `balance = opening - expenseOutflow + movementNet + incomeInflow`. `incomeInflow` sums non-deleted incomes with `accountId = account`, same currency, `date >= openingDate`. Income with no account is tracked but affects no balance. Spending analytics, budgets and daily allowance are unchanged (income is not an expense).
5. **Shared recurrence**: the cycle arithmetic moves from `Subscription` into `lib/src/utils/recurrence.dart` (`advanceByCycle`), used by both subscriptions and income schedules, so month-end anchoring (Jan 31 to Feb 28 to Mar 31) behaves identically. Subscription behaviour is unchanged and stays covered by its existing tests.
6. **Expected income** for a month (`IncomePlanner`, pure): received incomes dated in the month, plus every active schedule occurrence dated in the month at or after the schedule's current `nextDueDate` (so an overdue, unconfirmed occurrence still counts). Per currency; only the app currency feeds the suggestion.
7. **Budget suggestion** (advisory, never automatic): `suggested = expectedIncome - monthly subscriptions - monthly essentials`, floored at 0, shown in the budget sheet with a "Use suggestion" action. The user's manual monthly budget always wins. Subscriptions use `FinancialMetricsCalculator.normalizeSubscriptionToMonthly`; essentials use their monthly equivalent.
8. **Deferred**: pay-cycle periods (month starting on payday or semester) change every month-keyed query, `MonthlyBudgets.month` semantics and Insights; they need their own ADR. Runway to next income and per-account limits are also deferred.
9. **Backup**: `incomes` and `income_schedules` are optional extended tables (absence means no rows), `accountId` remapped through the `account` map; Full Replace deletes both before `accounts`. Older v2 files still restore.
10. **Opt-in / offline**: nothing appears until the user adds income. No notifications, no INTERNET permission.
11. **Archive/lock rules** extend ADR-0011: an account with incomes or schedules counts as having history (archive instead of delete; currency locked).

## Alternatives Considered
1. **Single `incomes` table with a recurring flag**: mixes expectation with fact; confirming or skipping an occurrence then needs row cloning. Rejected.
2. **Auto-post on due date (like subscriptions)**: wrong for irregular or late salary and silently corrupts balances. Rejected for confirm-on-arrival.
3. **Store income as a movement kind in `account_movements`**: loses source/title/schedule link and cannot represent income with no account. Rejected.
4. **Make the budget derive automatically from income**: surprising and breaks existing budgets. Rejected for an opt-in suggestion.
5. **Do pay-cycle budgets now**: too invasive for one change (Decision 8).

## Consequences
- **Positive**: Balance updates when salary is confirmed; users see expected income and a sane budget suggestion; recurrence logic is shared.
- **Negative / Trade-offs**: Another two tables to back up and test; confirm prompts need the user to open the app; budget remains calendar-month.
- **Neutral**: Schema v11 (26 tables).

## Related Code
- `lib/src/data/local/wallet_melt_database.dart`, `lib/src/data/repositories/drift/drift_income_repository.dart`
- `lib/src/analytics/income_planner.dart`, `lib/src/analytics/balance_calculator.dart`
- `lib/src/utils/recurrence.dart`
- `lib/src/screens/income/`

## Related Decisions
- [[ADR-0011-Accounts-Derived-Balance-and-Transfers]]
- [[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]
