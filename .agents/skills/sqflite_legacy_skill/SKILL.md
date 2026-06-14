---
name: sqflite_legacy_skill
description: Instructions to preserve and maintain the legacy sqflite database and repository access layer during transition phases.
---

# WalletMelt sqflite Legacy Skill

## Runtime Role
- **Database Engine:** sqflite acts as the original SQLite manager for WalletMelt V1. It opens the database file `wallet_melt.db` inside the device's native database directory.
- **V1 Schema Ownership:** sqflite manages table layouts (categories, expenses, grocery_items, category_budgets, sync_metadata) and indices defined in [database_schema.dart](file:///D:/Web%20Projects/WalletMelt/lib/src/data/schema/database_schema.dart).

## Coexistence & Downgrades
- **Do-Not-Delete Guidance:** Do not delete sqflite schema SQL strings or repository classes. They are required to support user sessions and act as fallbacks during Phase 4/5 migrations.
- **Downgrade Compatibility:** In `AppDatabase`, a non-destructive `onDowngrade` no-op handler is configured so the legacy sqflite runtime can still open the database after Drift upgrades `wallet_melt.db` to schema version 2. The sqflite runtime must continue to open the database successfully without crashing when V2 fields are present.

## Migration Caution
- **Centralized Schema Changes:** Future migrations to the core V1 tables are centralized inside `AppDatabase.onUpgrade` to keep UI code independent from storage evolution.
- **Maintain Foreign Keys:** Ensure that `PRAGMA foreign_keys = ON;` is executed inside `onConfigure` to enforce data constraints for categories, budgets, and expenses.

## Hard Rules
- Do not delete sqflite repositories or remove sqflite fallbacks.
- Do not assume Drift is fully live everywhere. Keep both runtimes coexisting safely.
