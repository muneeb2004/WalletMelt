---
type: architecture
status: stable
priority: high
created: 2026-09-13
updated: 2026-09-13
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
