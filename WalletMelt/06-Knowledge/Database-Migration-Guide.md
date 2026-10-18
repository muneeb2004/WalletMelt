---
type: knowledge
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-18
domain: database
related:
  - "[[Database-and-Drift-Architecture]]"
  - "[[ADR-0001-Drift-Primary-with-Sqflite-Fallback]]"
---

# Database Migration Guide

## 1. Schema Version Management
- Drift database schema version is defined in `lib/src/data/local/wallet_melt_database.dart`:
  ```dart
  static const currentSchemaVersion = 14;
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

> Drift (2026-10-15): code writes `MigrationAudit` rows only for v1→v2, v7→v8, v8→v9, v9→v10, v10→v11, v11→v12, v12→v13, v13→v14. Earlier steps rely on idempotent guards. Verified schema v14 / 30 tables.

## v9 to v10 (2026-10-17)
`_upgradeFromV9ToV10`: guarded `createTable` for `accounts` and `account_movements`, guarded `addColumn` for nullable `expenses.accountId`, three indexes, audit row (`audit_v9_v10_*`, status `completed`), preceded by the existing pre-migration backup. No data is rewritten: every existing expense keeps `accountId = NULL`. Because the audit row records the target version `to`, a database upgraded straight from v8 to v10 records its v8 step with `toVersion = 10`. Test: `test/database/schema_migration_v10_test.dart`.

## v10 to v11 (2026-10-17)
`_upgradeFromV10ToV11`: guarded `createTable` for `incomes` and `income_schedules` (and `accounts` if absent, since they reference it), two indexes, audit row `audit_v10_v11_*`. No data is rewritten. Test: `test/database/schema_migration_v10_test.dart` (v9 fixture opened at the current version) and `test/income/income_repository_test.dart`.

## v11 to v12 (2026-10-18)
`_upgradeFromV11ToV12`: guarded `addColumn` of nullable `accountId` on `debt_records` and `subscriptions`, two table-guarded indexes, audit row `audit_v11_v12_*`. No data rewritten. Test: `test/database/schema_migration_v12_test.dart`.

## v12 to v13 (2026-10-18)
`_upgradeFromV12ToV13`: guarded `createTable` for `savings_goals` and `savings_contributions`, two indexes, audit row `audit_v12_v13_*`. No data rewritten.

## v13 to v14 (2026-10-18)
`_upgradeFromV13ToV14`: guarded `createTable` for `committees` and `committee_events`, two indexes, audit row `audit_v13_v14_*`. No data rewritten.
