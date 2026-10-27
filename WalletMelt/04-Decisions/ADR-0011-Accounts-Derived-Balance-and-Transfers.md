---
type: adr
status: accepted
created: 2026-10-17
updated: 2026-10-27
domain: architecture
related:
  - "[[Balance-Income-and-Auto-Capture-Exploration]]"
  - "[[Gap-Analysis-vs-Code]]"
  - "[[ADR-0008-Deterministic-Financial-Metrics-Engine]]"
  - "[[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]"
  - "[[Database-Migration-Guide]]"
---

# ADR-0011: Accounts, derived balance and transfers

## Status
Accepted 2026-10-17 and implemented (Phase 1 of [[Balance-Income-and-Auto-Capture-Exploration]]). See Amendments for points refined during implementation.

## Context
Users asked to maintain their total balance. Today there is no account, wallet or payment-method concept and no income ([[Gap-Analysis-vs-Code]]), so the app can only say what was spent, not what is left. `Expenses` has `amount` (real) plus `amountMinorUnits`, a `currency`, and soft delete (`deletedAt`). Backup v2 covers all tables ([[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]). Schema is v9 with 22 tables. The app stays offline-only.

Income (salary, allowance) is needed for a meaningful balance, but is designed in Phase 2. This ADR must leave room for it without a second rewrite.

## Decision
1. **Accounts table** (`accounts`, schema v10): `id`, `name`, `type` (`cash|bank|wallet|card|other`), `currency`, `openingBalanceMinorUnits` (int), `openingDate`, `iconKey`, `colorRole`, `sortOrder`, `isArchived`, `includeInTotal` (bool), `createdAt`, `updatedAt`, `deletedAt`. One currency per account.
2. **Balance is derived, never stored.**
   `balance = openingBalance + sum(inflows) - sum(outflows)` over non-deleted rows dated on/after `openingDate`. Edits, soft deletes and restores therefore cannot drift. A cached value is allowed only as an in-memory projection.
3. **Expenses link**: add nullable `Expenses.accountId` (FK to `accounts`, `ON DELETE RESTRICT`). `NULL` means "unassigned": excluded from every account balance and shown as an "Unassigned" count with a one-tap bulk assign. Existing rows stay `NULL`; the migration never guesses.
4. **Ledger for non-expense movements**: new `account_movements` table: `id`, `accountId`, `kind` (`adjustment|transfer_in|transfer_out`), `amountMinorUnits` (signed int), `date`, `transferGroupId` (nullable, shared by the two legs), `notes`, timestamps, `deletedAt`. Phase 2 adds `income` as a new `kind` (or links an `Incomes` table); no schema change to existing rows is needed.
   - **Transfers** are two legs written in one transaction with the same `transferGroupId`. Cross-currency transfers require the user to enter both amounts (no FX table; the implied rate is just displayed). Deleting a transfer soft-deletes both legs together.
   - **Reconcile**: user enters the real balance; the app writes one `adjustment` for the difference, labelled and reversible. History is never rewritten.
5. **Analytics exclusion**: transfers and adjustments are not spending. `FinancialMetricsCalculator` ([[ADR-0008-Deterministic-Financial-Metrics-Engine]]) reads only `Expenses`, so budgets, daily allowance and Insights are unchanged. The transparency screen gets a "Balance" entry documenting the formula.
6. **Totals across currencies**: the dashboard shows one total per currency; no conversion. Accounts with `includeInTotal = false` are listed but not summed.
7. **Opt-in UX**: no accounts exist by default and the Dashboard shows an unobtrusive "Track your balance" prompt. Add-expense gets an optional account picker that defaults to the last used account. Hide-balance toggle (privacy) applies to the balance card and screenshots mode.
8. **Debts stay separate** in Phase 1: repayments do not move account balances. A later ADR may link `DebtRepayments` to an account (it needs the same signed-movement treatment). Documented in the UI as "debts are tracked separately".
9. **Money arithmetic** uses integer minor units for all new columns with the app-wide fixed exponent 2 (`toMinorUnits`). When `Expenses.amountMinorUnits` is null (legacy rows), the balance query falls back to `ROUND(amount * 100)`.
10. **Backup/restore**: bump the backup format to include `accounts` and `account_movements` and the `accountId` column; v2 files restore with `accountId = NULL` and no accounts (backward compatible). Safe Merge matches accounts by `id`; Full Replace verifies row counts and checksums as for other tables. See [[Backup-Format-Specification]].
11. **Migration v9 to v10** (`_upgradeFromV9ToV10`): create two tables, add nullable `accountId` with an index, write a `MigrationAudit` row, and take the existing pre-migration backup. No data rewriting.

## Alternatives Considered
1. **Stored running balance column on accounts**: simpler reads, but any edit/delete/restore/import must patch it; drift is silent and unrecoverable. Rejected in favour of derivation (cost is a cheap indexed sum).
2. **Payment-method text tag on Expenses only**: smallest change, but cannot model opening balance, transfers or reconciliation. Rejected; an account subsumes it.
3. **Full double-entry ledger replacing Expenses**: most correct, but rewrites the core table, analytics, backup and every screen. Rejected as disproportionate; `account_movements` gives the needed non-expense entries.
4. **Single global "current balance" number the user edits**: matches the feedback literally, but breaks per-wallet clarity and cannot support auto-capture (Phase 3). Rejected.
5. **Mandatory account on every expense**: cleaner data, but forces setup on all existing users and breaks quick-add. Rejected for nullable, opt-in.
6. **FX conversion with stored rates now**: out of scope; adds stale-rate risk offline. Deferred.

## Consequences
- **Positive**: Balance is always consistent with entries; transfers and reconciliation are first-class; Phase 2 income and Phase 3 auto-capture plug in as new movement kinds; no INTERNET permission; existing analytics untouched.
- **Negative / Trade-offs**: Balance is only as accurate as the user's assignment of expenses (unassigned count mitigates); balance queries sum over history (needs `(accountId, date)` index and a perf test at 50k rows); another table family to back up and test; per-currency totals instead of one number may disappoint multi-currency users.
- **Neutral**: Schema v10; the "Balance" formula is added to the transparency screen; `Constitution` scope unchanged (still offline, no SMS).

## Test and verification requirements
- Migration test v9 to v10 on a populated fixture (row counts equal, `accountId` all `NULL`, audit row written).
- Unit tests: balance after add/edit/soft-delete/restore; transfer atomicity and paired delete; cross-currency transfer; reconcile adjustment; archived and `includeInTotal` handling; legacy rows without minor units.
- Backup round-trip (export v10, Full Replace and Safe Merge) and v2-file restore.
- Widget tests: Dashboard balance card (hidden/shown, empty state), account picker defaulting.
- Update `test/theme/design_token_guard_test.dart` only downward; use `WMCard` and colour roles.

## Related Code (planned)
- `lib/src/data/local/wallet_melt_database.dart` (tables, `_upgradeFromV9ToV10`)
- `lib/src/data/repositories/drift/` (new account repository, balance queries)
- `lib/src/analytics/` (balance calculator, kept pure like [[ADR-0008-Deterministic-Financial-Metrics-Engine]])
- backup export/import services and `Backup-Format-Specification`

## Related Decisions
- [[ADR-0008-Deterministic-Financial-Metrics-Engine]]
- [[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]
- [[ADR-0005-Safe-Merge-Transactional-Restore]]
- Next: ADR for income and pay-cycle budgets (Phase 2); later ADR for opt-in notification capture (Phase 3).

## Amendments (2026-10-17, from implementation)
a. **Currency guard**: an expense only counts toward an account of the same currency (`e.currency = a.currency` in the balance query). The expense form offers only same-currency, non-archived accounts (an already linked archived account stays selectable so editing never silently unassigns), and the form saves in the app currency, so accounts in another currency cannot receive new expenses until multi-currency entry exists.
b. **Backup**: `accounts`, `account_movements` and `expense_account_links` are optional keys; absence means no rows. Expenses cannot carry `accountId` through the core encoder, so the link list is applied after accounts are inserted.
c. **Archived accounts** stay in `AppState.accounts` (needed to preserve links on edit) but are excluded from totals and pickers.
d. **Currency lock**: an account's currency cannot change once it has expenses or movements.
e. **Audit rows** record the migration target `to`, so a v8 database upgraded to v10 stores the 8-to-9 step with `toVersion = 10`.
f. **Deferred**: hide-balance state is per session (not persisted); the Dashboard prompt and balance card are the only entry points besides Settings; no demo account is seeded for screenshots yet, so the Dashboard setup prompt is suppressed when `SecurityUtils.isScreenshotMode` is set (published screenshots unchanged).

## Amendment 2026-10-18 (release 1.7.1): simpler accounts
g. **Three account types.** `type` is now `cash|bank|wallet`. `card` and `other` were removed because they only changed an icon and the app had not been distributed, so no legacy mapping is kept; `accountTypeFromName` falls back to `cash` for any unknown stored value. No schema change (still v14, the column is plain text).
h. **Add account** asks for a name and an optional starting balance. Type, currency and include-in-total sit under "More options" (open when editing).
i. **Add money / Spend money** write one signed `adjustment` movement (`DriftAccountRepository.recordAdjustment`, `AppState.adjustAccountBalance`) with the amount and an optional note. They are not expenses: budgets, daily allowance and Insights ignore them (the sheet says so and points to Add expense). Deleting the entry reverses the balance.
j. **Correct balance** (the old "Update balance" reconcile) moved into the account's overflow menu for the rare case where the real balance differs.

## Amendment 2026-10-27: balance visibility and account sheet
User feedback: the balance was easy to miss (it sat below the spend hero and quick actions), gave no sign that it opens, and "Correct balance" was hidden in a three-dot menu. Decision: spend and balance share the top row as equal tiles with a visible chevron; the account sheet lists Transfer, Correct balance and Edit as labelled rows; all account forms share one layout. See [[Design-System-and-UX]]. No data or behaviour change.
