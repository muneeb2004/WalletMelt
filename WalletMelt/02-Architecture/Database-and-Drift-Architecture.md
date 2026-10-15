---
type: architecture
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-15
domain: architecture
related:
  - "[[Application-Architecture]]"
  - "[[ADR-0001-Drift-Primary-with-Sqflite-Fallback]]"
  - "[[ADR-0002-Database-Lifecycle-Singleton]]"
---

# Database and Drift Architecture

## 1. Storage Engine
- **Engine**: SQLite via Drift (`drift_flutter` / `sqlite3_flutter_libs`).
- **Schema Version**: `9`.
- **Database File**: Stored in platform database directory as `wallet_melt.db`.

## 2. Table Topology (22 Tables)
```text
Core Financial:
  Categories ──< Expenses ──< GroceryItems
                      └──< ExpenseItems
                      └──< Receipts
                      └──< FuelTransactions ──< FuelComponents
  Categories ──< CategoryBudgets
  MonthlyBudgets

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
- Schema version is unchanged (9, 22 tables). Backup v2 covers 20 of them; `migration_audit` and `sync_metadata` are device-local and excluded ([[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]).
- Foreign keys are enabled in `beforeOpen`; `PRAGMA foreign_keys` cannot be toggled inside a transaction, so restores keep them ON and verify with `PRAGMA foreign_key_check`.
