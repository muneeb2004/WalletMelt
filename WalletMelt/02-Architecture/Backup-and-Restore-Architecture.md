---
type: architecture
status: stable
priority: medium
created: 2026-09-13
updated: 2026-10-15
domain: architecture
related:
  - "[[ADR-0005-Safe-Merge-Transactional-Restore]]"
  - "[[Database-and-Drift-Architecture]]"
---

# Backup and Restore Architecture

## 1. Guardrails (see [[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]])
- **Safe Merge** is the default and works for v1 and v2 backups.
- **Full Replace** exists only for complete v2 backups, in one transaction, with foreign keys ON and a `foreign_key_check` gate; it never runs a destructive "recovery" pass.
- Both modes restore inside a single Drift transaction and roll back entirely on any failure.
- A complete v2 pre-restore safety backup is written before any mutation; its path is shown if a restore fails.

## 2. Pipeline
```text
select file -> decrypt/unzip -> validate (format 1|2, v2: checksum + schema + extended shape)
 -> preview (counts) -> conflict detection / dry-run plan -> explicit confirmation
 -> safety backup -> transaction { core sections, monthly budgets, extended section,
    settings, minor-unit backfill, count + relationship + foreign_key_check }
 -> refresh AppState
```

## 3. Components
- `WalletMeltJsonBackupEncoder` (v1/v2 JSON, checksum), `BackupExtendedTables` (generic per-table export/import), `WalletMeltJsonBackupValidator`, `WalletMeltJsonBackupPreviewService`, `WalletMeltJsonBackupConflictService`, `WalletMeltJsonRestoreDryRunPlanner`, `WalletMeltJsonRestoreService` (`restoreSafeMerge`, `restoreFullReplace`), `BackupEncryptionService`.
- Format details: [[Backup-Format-Specification]].

## 4. Verification
`test/services/export/backup_v2_roundtrip_test.dart` seeds all tables, exports v2 and asserts per-table row counts and an empty `foreign_key_check` after Full Replace (empty and populated destination) and Safe Merge; also tamper detection and v1 refusal for Full Replace.

## 5. Preview (2026-10-15)
`WalletMeltBackupPreview.extendedCounts` carries per-table row counts of the v2 `extended` section; the restore dialog shows debts, subscriptions, payees, essentials and fuel logs. Full Replace is disabled in the dialog for v1 backups. ZIP `metadata.json` records the real Drift `schema_version`.
