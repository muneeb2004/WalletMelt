---
type: adr
status: accepted
created: 2026-08-28
updated: 2026-09-13
domain: architecture
related:
  - "[[ADR-0001-Drift-Primary-with-Sqflite-Fallback]]"
  - "[[Database-and-Drift-Architecture]]"
---

# ADR-0002: Database Lifecycle Singleton and Guarded Boot

## Status
Accepted

## Context
During startup, both `AppState.initialize()` and Riverpod's `walletMeltDatabaseProvider` invoked `WalletMeltDatabase.open()` independently. This generated two concurrent file connection handles to `wallet_melt.db`, triggering Drift's "database opened twice" warning and creating potential SQLite database lock contention.

## Decision
Enforce a static cached singleton pattern in `WalletMeltDatabase.open()`:
1. Cache `_singleton` upon successful opening.
2. Guard concurrent boot calls via a cached `_singletonFuture`.
3. Provide `@visibleForTesting static void resetSingletonForTesting()` for test isolation.
4. Teardown ownership resides solely with Riverpod `ref.onDispose` (or test fixtures).

## Alternatives Considered
1. **Pass database handle manually everywhere**: Rejected because it polluted top-level constructor signatures across unrelated UI trees.
2. **Allow multiple read-only connections**: Rejected because WAL mode and locks across isolates added unnecessary platform complexity.

## Consequences
- **Positive**: Zero "opened twice" warnings, zero connection contention, safe asynchronous app startup.
- **Negative**: Requires explicit `resetSingletonForTesting()` when running multiple in-memory test fixtures.

## Related Code
- `lib/src/data/local/wallet_melt_database.dart`
- `lib/src/state/app_state.dart`
