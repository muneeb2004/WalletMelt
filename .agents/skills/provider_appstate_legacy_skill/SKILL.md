---
name: provider_appstate_legacy_skill
description: Guidelines to maintain and protect the legacy Provider/AppState runtime layer during the migration process.
---

# WalletMelt Provider/AppState Legacy Skill

## Workspace Staging Context
- **V1 baseline:** complete
- **Phase 1 Drift foundation:** PASS
- **Phase 2 Riverpod foundation:** PASS
- **Phase 3 Drift-backed repository boundary:** PASS
- **Phase 4 category/budget AppState read migration:** PASS for code/build/test
- **Phase 5 budget write migration behind AppState:** PASS for code/build/test
- **Phase 6A first direct Riverpod read consumer:** PASS for code/build/test
- **Android runtime QA:** pending, blocked by emulator startup failure

## AppState Role
- **Session Coordinator:** `AppState` acts as the main live controller tracking user session data. It initializes databases, loads settings, updates currencies, and manages active filters.
- **Write Gateway:** All write/mutation operations (adding custom categories, adding/updating expenses, soft-deleting items, setting budgets) must route through `AppState`.

## Coexistence Rules
- **Do Not Remove AppState:** The `AppState` class is the backbone of the V1 screen templates and cannot be deleted or bypassed during the migration process.
- **Fallback Operations:** For migrated tables (e.g., categories, budgets), `AppState` methods must attempt reading from Drift repositories first. If the new Drift layer throws an error, it must immediately fallback to sqflite repositories to ensure uninterrupted app functionality.

## Public API Preservation
- **Keep Signatures Intact:** Do not change the names or arguments of public methods (e.g., `addExpense()`, `updateExpense()`, `setBudget()`) to avoid breaking UI templates.
- **Maintain Properties:** Preserve session fields (like `categories`, `expenses`, `deletedExpenses`, `currentBudgets`) so screens utilizing `context.watch<AppState>()` continue to compile.

## Refresh Patterns
- **Notify Listeners:** Ensure that all mutation routines execute `await refresh()` and trigger `notifyListeners()` to update the listening UI.
- **Loading Indicators:** Set `isLoading = true` and call `notifyListeners()` when starting database initializations, reverting it back to `false` when finished.

## Risk Areas
- **Expense Flow Isolation:** Do not migrate expense writes to Drift without explicit approval. All expense flows must run on the legacy sqflite path.
- **Database Locks:** Avoid opening multiple connections to the database file. Ensure that both sqflite and Drift use shared database configurations.
