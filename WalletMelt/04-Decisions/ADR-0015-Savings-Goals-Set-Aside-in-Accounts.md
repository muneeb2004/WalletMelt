---
type: adr
status: accepted
created: 2026-10-18
updated: 2026-10-18
domain: architecture
related:
  - "[[ADR-0011-Accounts-Derived-Balance-and-Transfers]]"
  - "[[ADR-0014-Debts-and-Subscriptions-Move-Account-Balances]]"
  - "[[Student-Market-Strategy]]"
---

# ADR-0015: Savings goals set aside inside an account

## Status
Accepted 2026-10-18. Owner chose "set aside inside an account": a goal reserves part of an account's balance; the balance itself does not change.

## Context
Users want to save toward a target (laptop, fees, Hajj) without moving money to another place. Real balances (ADR-0011) must stay equal to what the bank, wallet or cash holds, so a goal can only be a reservation on top of an account, not a second balance.

## Decision
1. **`savings_goals`** (schema v13): `id`, `name`, `targetMinorUnits` (> 0), `currency`, `accountId` (required FK to `accounts`, `ON DELETE RESTRICT`), `targetDate` (nullable ISO date), `status` (`active|achieved|archived`), `createdAt`, `updatedAt`, `deletedAt`. The goal's currency equals its account's currency.
2. **`savings_contributions`**: `id`, `goalId` (FK to `savings_goals`, `ON DELETE RESTRICT`), `amountMinorUnits` (signed: positive sets money aside, negative releases it), `date`, `notes`, `createdAt`, `updatedAt`, `deletedAt`. Contributions are facts; progress is derived.
3. **Derived, never stored**: `saved(goal) = sum(non-deleted contributions)`; `reserved(account) = sum(saved(goal))` over that account's active goals (achieved and archived goals reserve nothing); `freeToSpend(account) = balance(account) - reserved(account)`. Account balance (ADR-0011/0012/0014) is unchanged by goals.
4. **Over-reservation is allowed but flagged**: free to spend may go negative (for example after spending the saved money); the UI shows it as "Reserved more than the balance" instead of blocking the entry.
5. **Lifecycle**: add goal, set aside, release, mark achieved (releases the reservation by writing one negative contribution for the remaining saved amount, so history stays), archive, delete (soft). Reaching the target shows an "on track / reached" state; reaching it never auto-completes.
6. **Surfaces**: a Goals screen (`/goals`) with progress bars; per-account "set aside" and "free to spend" on the Accounts screen; the Dashboard balance card shows free to spend under the total when anything is reserved (per currency, same inclusion rules as totals).
7. **Backup**: `savings_goals` and `savings_contributions` are optional extended tables (missing = none); `accountId` remapped through the `account` map; Full Replace deletes contributions, then goals, before `accounts`. A contribution pointing at a missing goal is skipped; a goal pointing at a missing account is skipped.
8. **Archive/lock rules**: an account with goals counts as having history (archived instead of deleted; currency locked).
9. **Not analytics**: goals never appear in spending, budgets or allowance. Pace suggestions ("save X per month to reach it by date") are advisory text computed from target, saved and target date.

## Alternatives Considered
1. **Separate savings pot with its own balance**: duplicates money and breaks "balance equals reality". Rejected by the owner.
2. **Target tracker with manual progress**: no link to accounts, cannot show free to spend. Rejected by the owner.
3. **Store `reservedAmount` on accounts**: drifts on edits and deletes. Rejected for derivation.

## Consequences
- **Positive**: Real balances stay truthful; users see what is genuinely free; fully derived.
- **Negative / Trade-offs**: Two more tables; a goal tied to one account cannot span accounts; over-reservation needs clear wording.
- **Neutral**: Schema v13 (28 tables).

## Related Code (planned)
- `lib/src/data/local/wallet_melt_database.dart`, `lib/src/data/repositories/drift/drift_goal_repository.dart`
- `lib/src/analytics/goal_planner.dart` (pure progress and pace maths)
- `lib/src/screens/goals/`, Dashboard balance card, Accounts screen

## Related Decisions
- [[ADR-0011-Accounts-Derived-Balance-and-Transfers]]
- [[ADR-0014-Debts-and-Subscriptions-Move-Account-Balances]]

## Implementation notes (2026-10-18)
- Migration `_upgradeFromV12ToV13`; audit row `audit_v12_v13_*`. `DriftGoalRepository` (`listProgress`, `createGoal`, `setAside`, `release`, `markAchieved`, `archive`, `reopen`, `deleteGoal`); pure `GoalPlanner`; `AppState` exposes `goalProgress`, `reservedByAccount`, `freeToSpendFor`, `freeToSpendTotals`.
- Restore skips a goal whose account is absent and a contribution whose goal is absent.
- Screens: `/goals` (entry from the Accounts app bar), free to spend on the Dashboard balance card and per account. The goal detail dialog owns its controller in a small widget (a disposal bug was caught by the widget test).
- Tests: `test/goals/savings_goals_test.dart`, `test/screens/goals_screen_test.dart`, backup round trip.
