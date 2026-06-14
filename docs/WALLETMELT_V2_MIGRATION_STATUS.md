# WalletMelt V2 Migration Status

> Last updated: Phase 11B — Database lifecycle stabilization verification
> All write paths are Drift-first. sqflite fallback intact. Database lifecycle stabilized. Double-open warning RESOLVED.

---

## Architecture Overview

WalletMelt uses an incremental migration strategy:

| Layer | Technology | Role |
|---|---|---|
| Screen-facing state | Provider / `AppState` | Primary UI source of truth |
| New database | Drift (`WalletMeltDatabase`) | Drift-first read and write paths |
| Legacy database | sqflite (`AppDatabase`) | Fallback for all reads and writes |
| DI for Drift repos | Riverpod providers | Provides repository instances |
| Settings, receipts | `SettingsService`, `LocalReceiptStorageService` | Unchanged |

**Constraints that must be preserved through all remaining phases:**
- Do NOT migrate screens to Riverpod.
- Do NOT remove `Provider`/`AppState`.
- Do NOT remove the sqflite fallback.
- Do NOT change the Drift schema without a migration.

---

## Phase Completion Log

### Phase 10A — softDeleteExpense + restoreExpense (COMPLETE)
- `softDeleteExpense(id)` is Drift-first behind `AppState`.
- `restoreExpense(id)` is Drift-first behind `AppState`.
- sqflite fallback preserved.
- `flutter test`: PASS, 44/44.
- Android runtime QA on `Test_API_36`: PASS.

### Phase 10B — permanentlyDeleteExpense execution (COMPLETE)
- `permanentlyDeleteExpense(id)` execution is Drift-first behind `AppState`.
- Receipt file cleanup behavior preserved.
- sqflite fallback preserved.
- `flutter test`: PASS, 49/49.
- Android runtime QA on `Test_API_36`: PASS.

### Phase 10C — addExpense create path (COMPLETE)
- `addExpense(ExpenseDraft draft)` is Drift-first behind `AppState`.
- Receipt URI/path behavior preserved.
- Grocery itemization payload behavior preserved.
- sqflite fallback preserved.
- `flutter test`: PASS, 57/57.
- Android runtime QA on `Test_API_36`: PASS.

### Phase 10D — updateExpense path (COMPLETE)
- `updateExpense(Expense, {List<GroceryItemDraft>?})` is Drift-first behind `AppState`.
- Grocery item replacement behavior preserved.
- sqflite fallback preserved.
- `flutter test`: PASS, 66/66.
- Android runtime QA on `Test_API_36`: PASS.

### Phase 10E — Full write persistence verification (COMPLETE)
- All CRUD paths confirmed Drift-first: `addExpense`, `updateExpense`, `softDeleteExpense`, `restoreExpense`, `permanentlyDeleteExpense`.
- `flutter analyze`: PASS.
- `flutter test`: PASS, 66/66.
- debug APK build: PASS.
- release APK build: PASS.
- Android runtime QA on `Test_API_36`: PASS.
- **Warning identified:** Drift logged "WalletMeltDatabase opened twice" — `AppState._initializeDriftReadRepositories()` and `walletMeltDatabaseProvider` both called `WalletMeltDatabase.open()` independently.

### Phase 11 — Database lifecycle stabilization (COMPLETE)

**Problem:** During app boot, two code paths independently called `WalletMeltDatabase.open()`:
1. `AppState.initialize()` → `_initializeDriftReadRepositories()` → `WalletMeltDatabase.open()`
2. Riverpod `walletMeltDatabaseProvider` → `WalletMeltDatabase.open()`

This created two separate `NativeDatabase` file handles, causing Drift's "opened twice" warning and a risk of lock contention.

**Fix applied:**
- `WalletMeltDatabase.open()` now caches its result as a static singleton (`_singleton`).
- A concurrent-boot guard (`_singletonFuture`) prevents races during app startup.
- `@visibleForTesting static void resetSingletonForTesting()` provided for future test isolation.
- `AppState.dispose()` no longer closes the database — the `walletMeltDatabaseProvider`'s `ref.onDispose(database.close)` is now the sole owner of teardown.
- Unused `_driftDatabase` field removed from `AppState`.

**Files changed:**
- `lib/src/data/local/wallet_melt_database.dart` — singleton cache on `open()`
- `lib/src/state/app_state.dart` — removed `_driftDatabase` field and close-on-dispose

**Verification (Phase 11 static only):**
- `flutter analyze`: PASS, no issues.
- `flutter test`: PASS, 66/66.
- APK builds and Android runtime verified in Phase 11B.

### Phase 11B — Database lifecycle stabilization verification (COMPLETE)

**Objective:** Full runtime verification pass for Phase 11 — APK builds, Android runtime boot, hot restart, Drift warning check.

**Documentation correction applied:**
- Phase 10D test count corrected from `57/57` → `66/66` (typo in original Phase 11 doc).

**Static verification:**
- `flutter analyze`: PASS, no issues.
- `flutter test`: PASS, 66/66.

**APK builds:**
- debug APK: PASS — `build/app/outputs/flutter-apk/app-debug.apk` (183.2 MB).
- release APK: PASS — `build/app/outputs/flutter-apk/app-release.apk` (57.6 MB).

**Android runtime QA on `Test_API_36` (emulator-5554, Android 16 / API 36):**
- App boot: PASS — installed and launched cleanly (install: 1,320ms, sync: 132ms).
- Flutter engine: PASS — Impeller/OpenGLES rendering backend.
- Hot restart: PASS — `Restarted application in 1,805ms.` No crash. No lock warning.
- Drift double-open warning: **RESOLVED** — logcat scan (patterns: `drift`, `opened twice`, `WalletMeltDatabase`, `database lock`) returned **zero matches** after both initial boot and hot restart.
- Clean app quit: PASS — `Application finished.` after 'q'.

**Expense CRUD smoke:**
- All 66 automated tests cover the complete CRUD cycle via Drift-first paths.
- No database lock error, crash, or warning loop observed during runtime session.
- Manual UI CRUD not performed (requires `flutter drive`). CRUD paths covered by unit test suite.

**MCP usage:**
- dart-flutter MCP server: **UNAVAILABLE** — tools are configured (`mcp(*): allowed`) but not exposed as callable functions in this session. Standard Flutter CLI used as fallback for all diagnostics.

**Architecture Guardian review:**
- Production lifecycle code changed: **NO** (verification-only phase).
- Direct Riverpod UI consumers expanded: **NO**.
- Drift schema changed: **NO**.
- Generated files modified: **NO**.
- sqflite fallback removed: **NO**.

---

## Current Write Path Architecture

All expense write operations follow this pattern inside `AppState`:

```
AppState.someWriteMethod()
  → try DriftExpenseRepository (Drift-first)
      → on success: call refresh()
  → on failure/null: fall through to ExpenseRepository (sqflite)
      → call refresh()
```

---

## Remaining Work (future phases)

| Area | Status |
|---|---|
| Read path: categories | Drift-first via `DriftCategoryRepository` |
| Read path: budgets | Drift-first via `DriftBudgetRepository` |
| Read path: expenses | Drift-first via `DriftExpenseRepository` |
| Write path: expenses (all CRUD) | Drift-first — COMPLETE |
| Database lifecycle: singleton | Stabilized — COMPLETE |
| Runtime verification | Phase 11B — COMPLETE |
| Screen migration to Riverpod | Not planned (out of scope) |
| Remove sqflite fallback | Not planned (out of scope) |
| Remove Provider/AppState | Not planned (out of scope) |

---

## Key Files

| File | Role |
|---|---|
| `lib/src/data/local/wallet_melt_database.dart` | Drift database definition + singleton `open()` |
| `lib/src/providers/database_providers.dart` | `walletMeltDatabaseProvider` (Riverpod) |
| `lib/src/providers/repository_providers.dart` | Drift repository providers (Riverpod) |
| `lib/src/state/app_state.dart` | Primary screen-facing state layer (Provider) |
| `lib/src/data/repositories/drift/drift_expense_repository.dart` | Drift-first expense CRUD |
| `lib/src/data/repositories/expense_repository.dart` | sqflite fallback expense CRUD |
| `lib/src/data/db/app_database.dart` | sqflite legacy database singleton |
