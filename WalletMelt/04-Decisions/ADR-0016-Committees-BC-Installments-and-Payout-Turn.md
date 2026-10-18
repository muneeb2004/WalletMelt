---
type: adr
status: accepted
created: 2026-10-18
updated: 2026-10-18
domain: architecture
related:
  - "[[ADR-0011-Accounts-Derived-Balance-and-Transfers]]"
  - "[[ADR-0012-Income-Schedules-and-Budget-Suggestion]]"
  - "[[ADR-0014-Debts-and-Subscriptions-Move-Account-Balances]]"
  - "[[Student-Market-Strategy]]"
---

# ADR-0016: Committees (BC): monthly installments and a payout turn

## Status
Accepted 2026-10-18. Owner chose "monthly installment with payout turn": installments you pay reduce an account and your payout adds money to an account.

## Context
A committee (BC) is a rotating savings circle common in Pakistan: N members each pay a fixed amount every month, and each month one member receives the whole pot. Members pay in every month including their own payout month. Users want to track what they pay, when their turn comes and what they receive, and want the balance to follow.

## Decision
1. **`committees`** (schema v14): `id`, `name`, `monthlyMinorUnits` (> 0, the user's installment), `memberCount` (2 to 60), `payoutMonth` (1 to `memberCount`, the user's turn), `payoutMinorUnits` (> 0, defaults to `monthly x memberCount`, editable because pots vary), `currency`, `accountId` (nullable FK to `accounts`, `ON DELETE RESTRICT`; where installments are paid from and the payout is deposited), `startDate` (first installment date, ISO), `status` (`active|completed|archived`), `createdAt`, `updatedAt`, `deletedAt`.
2. **`committee_events`**: `id`, `committeeId` (FK `ON DELETE RESTRICT`), `kind` (`installment|payout`), `monthIndex` (1 to `memberCount`), `amountMinorUnits` (> 0, actually paid or received), `date`, `notes`, timestamps, `deletedAt`. At most one live `installment` and one live `payout` per `(committeeId, monthIndex)` (enforced in the repository). Events are facts the user confirms; nothing posts automatically.
3. **Schedule is derived**: installment `k` is due on `addMonthsClamped(startDate, k - 1, startDay)` (shared `recurrence.dart`, month-end safe). The payout is expected on the due date of `payoutMonth`. The next due installment is the lowest `k` with no live installment event.
4. **Balance**: for a committee linked to account A, in A's currency, dated on or after A's opening date: installment events are money out, payout events are money in. Formula becomes `balance = opening - expenseOutflow + movementNet + incomeInflow + debtNet + committeeNet` (ADR-0011/12/14). Unlinked committees only track progress.
5. **Prompts**: the Dashboard shows the oldest due item: "Did you pay your installment for month k?" (**Paid** records it at its due date with the amount editable, or **Later** dismisses for this session) and, in the payout month, "Did you receive your payout?" (**Received** with amount editable). Skipping is not offered because a missed BC payment is not a neutral event; **Later** changes nothing.
6. **Progress and totals**, pure and derived: installments paid, remaining, `totalToPay = monthly x memberCount`, `paidSoFar`, `payoutReceived`, `netPosition = payoutReceived - paidSoFar` once complete and `payoutMinorUnits - totalToPay` as the expected net. A committee becomes `completed` when all installments and the payout are recorded.
7. **Not spending**: committee flows do not appear in budgets, allowance or Insights (like debts and goals).
8. **Backup**: `committees` and `committee_events` are optional extended tables (missing = none); `accountId` is a nullable link dropped when the account is absent; an event whose committee is absent is skipped. Full Replace deletes events then committees before `accounts` and after nothing else depends on them.
9. **Archive/lock rules** (ADR-0011): an account with committees counts as having history.
10. **Out of scope**: lucky-draw committees (random turn), members' names and their payments, bidding committees, penalties. The user's own installments and payout only.

## Alternatives Considered
1. **Create real expenses and incomes for installments and the payout**: pollutes budgets and Insights with savings movements. Rejected for derived committee flows.
2. **Track every member's payments**: much larger surface and personal data of other people. Rejected; out of scope.
3. **Auto-post installments on their due date**: wrong when a payment is late or skipped. Rejected for confirm-on-paid.
4. **Reminders only, no balance link**: the owner chose the balance-linked model.

## Consequences
- **Positive**: Clear picture of paid, remaining and payout; balance follows real money; no pollution of spending analytics; shared recurrence maths.
- **Negative / Trade-offs**: Two more tables; balance SQL gains another aggregate; a user who changes the committee amount mid-way edits future installment amounts only through the confirmation dialog.
- **Neutral**: Schema v14 (30 tables).

## Related Code (planned)
- `lib/src/data/local/wallet_melt_database.dart`, `lib/src/data/repositories/drift/drift_committee_repository.dart`
- `lib/src/analytics/committee_planner.dart`, `lib/src/analytics/balance_calculator.dart`
- `lib/src/screens/committees/`, Dashboard due card

## Related Decisions
- [[ADR-0014-Debts-and-Subscriptions-Move-Account-Balances]]
- [[ADR-0015-Savings-Goals-Set-Aside-in-Accounts]]

## Implementation notes (2026-10-18)
- Migration `_upgradeFromV13ToV14`; audit row `audit_v13_v14_*`. `DriftCommitteeRepository` (`create`, `recordInstallment`, `recordPayout`, `undoEvent`, `setAccount`, `archive`, `reopen`, `delete`; completes automatically when every installment and the payout are recorded); pure `CommitteePlanner` (`dueDate`, `dueItems`, `expectedNet`, `netSoFar`).
- Balance SQL adds `committeeNet` (installments out, payout in) for committees linked to the account in the account currency, dated on or after the opening date.
- Restore skips events whose committee is absent and drops a committee's account link when the account is absent.
- UI: `/committees` (icon on the Accounts app bar), detail sheet with per-month rows, Dashboard confirm card (**Later** hides an item for the session only).
- Tests: `test/committees/committee_test.dart`, `test/screens/committees_screen_test.dart`, backup round trip.
