---
type: adr
status: accepted
created: 2026-10-15
updated: 2026-10-15
domain: architecture
related:
  - "[[ADR-0005-Safe-Merge-Transactional-Restore]]"
  - "[[Backup-and-Restore-Architecture]]"
  - "[[Backup-Format-Specification]]"
  - "[[Technical-Debt-Registry]]"
---

# ADR-0009: Complete Backup v2 and Safe Full Replace

## Status
Accepted (2026-10-15). Amends [[Project-Constitution]] §2.6 and refines [[ADR-0005-Safe-Merge-Transactional-Restore]].

## Context
A bug hunt on 2026-10-15 found (verified with a real in-memory database test):
- `RestoreMode.fullReplace` existed in code and UI although the Constitution and ADR-0005 forbid destructive overwrites.
- It crashed with `FOREIGN KEY constraint failed` as soon as the database held a subscription (or any row referencing a category), and its "recovery from safety snapshot" path then failed too.
- Backups (format v1) did not contain debts, repayments, payees, subscriptions, essentials, fuel, grocery templates, stores, units, items, aliases, expense items or receipts, so no restore could be faithful.
- Monthly budgets were deleted by full replace but never reinserted.

User instruction (2026-10-15): "I need to enhance and improve the backup so decide based on that." Historical rationale for the original `fullReplace`: Unknown.

## Decision
1. **Backup format v2** (`metadata.format_version = 2`): adds an `extended` section covering every table the v1 sections do not own, `metadata.schema_version`, and a required `metadata.checksum` (`sha256:` over the compact JSON of the document without the checksum). v1 files remain readable.
2. **Full Replace is kept, but only as a complete, transactional, verified operation**:
   - allowed only for v2 backups (v1 backups: Safe Merge only);
   - foreign keys stay ON; children are deleted before parents and inserted after them;
   - `PRAGMA foreign_key_check` must be clean before commit, otherwise the whole transaction rolls back;
   - no destructive fallback "recovery" pass; the pre-restore safety backup file stays on disk;
   - the safety backup itself is a complete v2 backup.
3. **Safe Merge also restores the extended section**, deduplicating on natural keys (`normalizedName` of payees/stores/items/aliases), remapping foreign keys, never touching pre-existing expenses' children, and refusing to commit if it adds foreign-key violations.
4. Minor-unit columns are written by repositories and back-filled after every restore.

## Constitution amendment (§2.6)
"Restores are Safe-Merge only" becomes: Safe-Merge is the default; Full Replace is permitted only for complete v2 backups, in a single transaction, behind explicit user confirmation and a pre-restore safety backup, with foreign-key verification. Silent destructive overwrites remain forbidden.

## Consequences
- Positive: faithful round trip of all 20 data tables (tested), tamper detection, no more FK crash, no data-loss "recovery".
- Negative: larger backup files; older app versions reject v2 files (intended).
- Excluded on purpose: `migration_audit`, `sync_metadata` (device-local bookkeeping).

## Related Code
`lib/src/services/export/wallet_melt_json_backup_extended_tables.dart`, `..._backup_encoder.dart`, `..._backup_validator.dart`, `..._restore_service.dart`; tests: `test/services/export/backup_v2_roundtrip_test.dart`.
