---
type: adr
status: accepted
created: 2026-10-18
updated: 2026-10-18
domain: architecture
related:
  - "[[ADR-0011-Accounts-Derived-Balance-and-Transfers]]"
  - "[[ADR-0012-Income-Schedules-and-Budget-Suggestion]]"
  - "[[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]"
---

# ADR-0014: Debts and subscriptions move account balances

## Status
Accepted 2026-10-18. Owner chose one optional account per subscription; debts follow the same opt-in pattern.

## Context
After ADR-0011 and ADR-0012 the balance reflects expenses, transfers, reconciles and income, but two real money flows are missing: debt principal and repayments, and subscription renewals (which create expenses with no account). The balance therefore drifts from reality for users with loans or subscriptions.

## Decision
1. **Schema v12**: nullable `accountId` (FK to `accounts`, `ON DELETE RESTRICT`) on `debt_records` and `subscriptions`. NULL means "not linked", exactly as today, so nothing changes for existing data.
2. **Subscriptions**: a renewal expense is created with `accountId = subscription.accountId` only when that account is active (not archived or deleted) and its currency equals the subscription currency; otherwise the expense is created unassigned. The renewal remains an ordinary expense, so the balance rule and all spending analytics are unchanged.
3. **Debts, derived balance** (no duplicate rows, so edits and deletes cannot drift). For a debt linked to account A in A's currency, dated on or after A's opening date:
   - Principal at creation: `loanGiven` takes money out (`-principal`), `loanTaken` brings money in (`+principal`). `owedToMe` and `iOwe` have no cash movement at creation (they record an obligation, not a hand-over).
   - Repayments: for `owedToMe` and `loanGiven` a repayment is money in (`+amount`); for `iOwe` and `loanTaken` it is money out (`-amount`). A repayment uses the debt's account.
   - Amounts use minor units, falling back to `ROUND(real * 100)` where a minor-unit column is null (repayments have none).
   - Formula becomes `balance = opening - expenseOutflow + movementNet + incomeInflow + debtNet`.
4. **Not analytics**: debt cash flow is not spending; budgets, allowance and Insights are unchanged. Debt screens and net-position maths are unchanged.
5. **Backup**: `accountId` travels inside the existing Drift `toJson` rows of `debt_records` and `subscriptions`; both are remapped through the `account` map. Older backups lack the key and restore as unlinked. Full Replace now deletes `accounts` after `debt_records` and `subscriptions` (RESTRICT keys).
6. **Archive/lock rules** (ADR-0011) count linked debts and subscriptions as account history.
7. **UI**: an optional "Paid from" / "Money goes to" account picker (same-currency, non-archived accounts) on the add-subscription and add-debt forms, defaulting to no account.
8. **Linking later (added in 1.5.1)**: an existing debt (debt detail sheet) or subscription (its action sheet) can be linked, re-linked or unlinked through a chooser limited to active same-currency accounts. Linking a debt applies its original loan amount and all repayments dated after the account start date, because debt cash flow is derived; subscription linking only affects future renewals.

## Alternatives Considered
1. **Write movement rows for debt events**: duplicates data and must be kept in sync with repayment edits and deletes. Rejected for derivation.
2. **Treat all four debt types as cash at creation**: wrong for obligations that never moved cash (`owedToMe`, `iOwe`). Rejected.
3. **Use the last-used account for renewals**: can silently pick the wrong account. Rejected by the owner.
4. **Per-repayment account override**: more UI for a rare case. Deferred.

## Consequences
- **Positive**: Balance matches reality for loans and subscriptions; opt-in; no change to analytics; no data migration.
- **Negative / Trade-offs**: Balance SQL gains two more aggregates; archived or foreign-currency accounts silently fall back to unassigned renewals; debts cannot be re-linked later in this release.
- **Neutral**: Schema v12 (still 26 tables).

## Related Code
- `lib/src/data/local/wallet_melt_database.dart`, `drift_account_repository.dart`, `drift_subscription_repository.dart`, `drift_debt_repository.dart`
- `lib/src/analytics/balance_calculator.dart`, `lib/src/state/app_state.dart` (`processSubscriptionRenewals`)
- `lib/src/screens/debt/debt_screen.dart`, `lib/src/screens/subscription/subscription_screen.dart`

## Related Decisions
- [[ADR-0011-Accounts-Derived-Balance-and-Transfers]]
- [[ADR-0012-Income-Schedules-and-Budget-Suggestion]]

## Implementation notes (2026-10-18)
- Migration `_upgradeFromV11ToV12` adds both columns and indexes with table-exists guards; audit row `audit_v11_v12_*`.
- Restore drops an optional account link (`debt_records`, `subscriptions`, `incomes`, `income_schedules`) that points at an account absent from the backup, instead of failing the whole restore.
- Tests: `test/accounts/debt_subscription_account_test.dart`, `test/database/schema_migration_v12_test.dart`, `test/services/export/backup_v2_roundtrip_test.dart`.
- Linking later: `DriftDebtRepository.setAccount` validates currency and active state; `AppState.setDebtAccount`; chooser `lib/src/components/account/choose_account_sheet.dart`. Tests: `test/accounts/link_existing_test.dart`.
