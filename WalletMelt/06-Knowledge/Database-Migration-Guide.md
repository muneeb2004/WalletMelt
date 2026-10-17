---
type: knowledge
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-17
domain: database
related:
  - "[[Database-and-Drift-Architecture]]"
  - "[[ADR-0001-Drift-Primary-with-Sqflite-Fallback]]"
---

# Database Migration Guide

## 1. Schema Version Management
- Drift database schema version is defined in `lib/src/data/local/wallet_melt_database.dart`:
  ```dart
  static const currentSchemaVersion = 10;
  ```
- **Rule**: Any change to table structure (columns, types, constraints, default values) **must**:
  1. Increment `currentSchemaVersion`.
  2. Implement a migration branch in the `MigrationStrategy` of `WalletMeltDatabase`:
     ```dart
     onUpgrade: (m, from, to) async {
       if (from < X) {
         // Idempotent migration statements
       }
     }
     ```
  3. Re-generate Drift code: `dart run build_runner build --delete-conflicting-outputs`.
  4. Record the migration in `MigrationAudit` table.

## 2. Migration Invariants
- Migrations must be **additive and idempotent**: use `m.addColumn(...)` or guarded `createTable(...)`.
- Never execute raw `DROP TABLE` on user-data tables during standard production upgrades.
- In automated tests, verify migration state using `WalletMeltDatabase.memory()` and ensure all table classes resolve cleanly.

> Drift (2026-10-15): code writes `MigrationAudit` rows only for v1→v2, v7→v8, v8→v9, v9→v10. Earlier steps rely on idempotent guards. Verified schema v10 / 24 tables.

## v9 to v10 (2026-10-17)
`_upgradeFromV9ToV10`: guarded `createTable` for `accounts` and `account_movements`, guarded `addColumn` for nullable `expenses.accountId`, three indexes, audit row (`audit_v9_v10_*`, status `completed`), preceded by the existing pre-migration backup. No data is rewritten: every existing expense keeps `accountId = NULL`. Because the audit row records the target version `to`, a database upgraded straight from v8 to v10 records its v8 step with `toVersion = 10`. Test: `test/database/schema_migration_v10_test.dart`.
