---
name: drift_skill
description: Rules for Drift table definitions, code generation commands, transaction audits, schema migrations, and default table seeding.
---

# WalletMelt Drift Skill

## Workspace Context
- **V1 baseline:** complete
- **Phase 1 Drift foundation:** PASS
- **Phase 2 Riverpod foundation:** PASS
- **Phase 3 Drift-backed repository boundary:** PASS
- **Phase 4 category/budget AppState read migration:** PASS for code/build/test
- **Phase 5 budget write migration behind AppState:** PASS for code/build/test
- **Phase 6A first direct Riverpod read consumer:** PASS for code/build/test
- **Android runtime QA:** pending, blocked by emulator startup failure

## Schema-Change Discipline
- **DSL Declarations:** Define table columns using Drift's DSL syntax in [wallet_melt_database.dart](file:///D:/Web%20Projects/WalletMelt/lib/src/data/local/wallet_melt_database.dart). Avoid writing custom raw SQLite CREATE TABLE statements for new tables.
- **Increment Versions:** Any modification to columns or tables requires incrementing `currentSchemaVersion` (e.g. from 2 to 3) in `WalletMeltDatabase`.
- **Pre-Migration Backups:** Ensure that `createPreV2BackupIfNeeded` is invoked before database migrations are run.
- **No Unapproved Schema Changes:** Do not add tables or alter schemas unless explicitly required.

## Code Generation Rules
- **Build Runner:** After any modification to tables, run build_runner:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Generated File Boundaries:** Do not edit `wallet_melt_database.g.dart` manually. Treat all errors in the generated file as compilation issues derived from `wallet_melt_database.dart`.

## Migration Safety
- **Migration Strategy:** Implement migrations inside `MigrationStrategy`'s `onUpgrade` callback. Maintain historical version steps (e.g. `from < 2`).
- **Post-Migration Audits:** Register migrations inside the `migration_audit` table. Add startup validations that verify row counts and spend totals match pre-migration statistics.
- **Transactional Migrations:** Wrap database schema migrations and legacy data migrations in a single database transaction.

## DAO/Repository Expectations
- **Decoupled Data Structures:** Repositories must map raw Drift rows to immutable domain models (e.g., [lib/src/types/category.dart](file:///D:/Web%20Projects/WalletMelt/lib/src/types/category.dart)) before returning them to controllers or providers. Repository behavior must match V1 contract behavior exactly.

## Seeded Data Behavior
- **Default Units:** Default units (piece, dozen, kg, g, L, ml, pack, bag, bottle, bill) must be seeded in the `units` table during `onCreate` or V2 upgrades.
- **Default Categories:** Standard financial categories (Food, Housing, Utilities, Transportation, Entertainment, Health, Shopping, Income, Miscellaneous) must be seeded inside the `categories` table.
- **Run validation tests:** Always execute `flutter test` after schema modifications.
