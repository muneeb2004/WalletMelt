---
type: architecture
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-18
domain: architecture
related:
  - "[[Application-Architecture]]"
  - "[[ADR-0001-Drift-Primary-with-Sqflite-Fallback]]"
  - "[[ADR-0002-Database-Lifecycle-Singleton]]"
---

# Database and Drift Architecture

## 1. Storage Engine
- **Engine**: SQLite via Drift (`drift_flutter` / `sqlite3_flutter_libs`).
- **Schema Version**: `12`.
- **Database File**: Stored in platform database directory as `wallet_melt.db`.

## 2. Table Topology (26 Tables)
```text
Core Financial:
  Categories ──< Expenses ──< GroceryItems
                      └──< ExpenseItems
                      └──< Receipts
                      └──< FuelTransactions ──< FuelComponents
  Categories ──< CategoryBudgets
  MonthlyBudgets

Accounts (v10, [[ADR-0011-Accounts-Derived-Balance-and-Transfers]]):
  Accounts ──< AccountMovements
  Accounts ──< Incomes, Accounts ──< IncomeSchedules (v11, [[ADR-0012-Income-Schedules-and-Budget-Suggestion]])
  Accounts ──< Expenses.accountId (nullable, ON DELETE RESTRICT)

Obligations & Debt:
  Payees ──< DebtRecords ──< DebtRepayments

Planning & Commitments:
  Categories ──< Subscriptions
  Categories ──< EssentialExpenseTemplates ──< FuelTemplateComponents
  GroceryTemplates

Metadata & Catalogs:
  Stores, Units, Items, ItemAliases, MigrationAudit, SyncMetadata
```

## 3. Singleton Database Lifecycle Rule
- `WalletMeltDatabase.open()` enforces a cached static singleton (`_singleton`) guarded by `_singletonFuture`.
- **Invariant**: Multiple instances of `WalletMeltDatabase` must never run concurrently in the app process. This eliminates SQLite database locks and Drift's "opened twice" assertion failures.
- Teardown is managed exclusively by Riverpod DI `ref.onDispose` or test hooks.

## Minor-unit columns (2026-10-15)
- `*MinorUnits` integer columns (expenses, category/monthly budgets, debts, subscriptions, grocery items) were previously filled **only by the v7->v8 migration**; new rows had NULLs. Repositories now write them for expenses, debts (including repayments, using integer arithmetic) and subscriptions.
- `WalletMeltDatabase.backfillMinorUnits()` fills any remaining NULLs from the REAL columns; it runs at the end of every restore transaction. Category-budget and grocery-item repositories still rely on this back-fill.
- As of 2026-10-15 the schema was v9 with 22 tables; since 2026-10-17 it is v11 with 26, and backup v2 covers 24 of them; `migration_audit` and `sync_metadata` are device-local and excluded ([[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]).
- Foreign keys are enabled in `beforeOpen`; `PRAGMA foreign_keys` cannot be toggled inside a transaction, so restores keep them ON and verify with `PRAGMA foreign_key_check`.

## Accounts and derived balance (2026-10-17, schema v10)
- `accounts` (one currency each, `openingBalanceMinorUnits`, `openingDate`, `isArchived`, `includeInTotal`, `colorRole` = a ColorScheme role name) and `account_movements` (signed `amountMinorUnits`; kinds `adjustment|transfer_in|transfer_out`; both legs of a transfer share `transferGroupId`). `expenses.accountId` is nullable; NULL = unassigned.
- Balance is **never stored**: `DriftAccountRepository.listBalances` aggregates SQL and `BalanceCalculator` applies the formula ([[Analytics-and-Calculations]]). Indexes: `expenses(accountId, date)`, `account_movements(accountId, date)`, `account_movements(transferGroupId)` (created in the migration and in `beforeOpen`).
- Accounts with history are archived rather than deleted (RESTRICT foreign keys). The legacy sqflite fallback has no account tables; `AppState.accountsAvailable` is false there and account UI is hidden.

## Income (2026-10-17, schema v11)
`incomes` (received facts, soft delete, optional `accountId` and `scheduleId`) and `income_schedules` (expectations: `cycle`, `startDate` anchor, `nextDueDate`, `status`). Both reference `accounts` with RESTRICT; an account with incomes or schedules is archived rather than deleted. Index `incomes(accountId, date)` and `income_schedules(status, nextDueDate)`. Money is integer minor units. See [[ADR-0012-Income-Schedules-and-Budget-Suggestion]].

## Debt and subscription account links (2026-10-18, schema v12)
`debt_records.accountId` and `subscriptions.accountId` are nullable FKs to `accounts` (RESTRICT) with indexes. Debt cash flow is derived in the balance SQL, never stored ([[ADR-0014-Debts-and-Subscriptions-Move-Account-Balances]]). Table count is unchanged (26).
