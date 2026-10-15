---
type: adr
status: accepted
created: 2026-08-20
updated: 2026-09-13
domain: architecture
related:
  - "[[ADR-0002-Database-Lifecycle-Singleton]]"
  - "[[Database-and-Drift-Architecture]]"
---

# ADR-0001: Drift Primary Persistence with Sqflite Fallback

## Status
Accepted

## Context
WalletMelt began with a legacy `sqflite` implementation (`AppDatabase`). As complexity grew (complex schemas, migrations, grocery items, fuel splits, subscriptions, debt), raw SQL string queries became brittle and error-prone. Drift was introduced to provide compile-time type safety, schema migrations, and reactive queries.

## Decision
Adopt Drift (`WalletMeltDatabase`) as the primary database engine for all read and write operations. Retain the legacy `sqflite` database and repository implementations as a fallback layer during migration phases. All write operations must execute Drift-first behind `AppState`.

## Alternatives Considered
1. **Immediate Total Sqflite Removal**: Rejected because an abrupt cutover risked silent data loss or regressions for existing local databases.
2. **Hive / Isar / ObjectBox**: Rejected due to lack of standard SQL relational capabilities, foreign keys, and complex migration guarantees.

## Consequences
- **Positive**: Type-safe Dart classes for all 22 tables, robust migration testing, and reliable transactions.
- **Negative**: Temporary dual-persistence maintenance cost while legacy fallback exists.

## Related Code
- `lib/src/data/local/wallet_melt_database.dart`
- `lib/src/data/repositories/drift/`
