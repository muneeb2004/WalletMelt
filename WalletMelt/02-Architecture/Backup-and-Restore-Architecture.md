---
type: architecture
status: stable
priority: medium
created: 2026-09-13
updated: 2026-10-27
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

## 6. Accounts (2026-10-17)
Schema v10 adds `accounts`, `account_movements` and `expense_account_links` to the extended section as **optional** keys, so pre-v10 v2 backups still validate and restore. Full Replace deletes `account_movements` and `accounts` after `expenses` (RESTRICT keys). Details: [[Backup-Format-Specification]] section 4, [[ADR-0011-Accounts-Derived-Balance-and-Transfers]].

## 7. Income (2026-10-17)
Schema v11 adds `incomes` and `income_schedules` to the optional extended keys; Full Replace deletes them before `expenses` and `accounts`. See [[Backup-Format-Specification]] section 5, [[ADR-0012-Income-Schedules-and-Budget-Suggestion]].

## 8. Settings field (2026-10-18)
The backup `settings` section now carries `budget_period_start_day` (1 to 28; missing = 1). Encoder and `_settingsFromJson` handle it; older backups restore unchanged. See [[Backup-Format-Specification]] section 6, [[ADR-0013-Budget-Period-Start-Day]].

## 9. Account links on debts and subscriptions (2026-10-18)
Schema v12 adds nullable `accountId` to `debt_records` and `subscriptions`. Restore order is accounts first; dangling links are nulled; Full Replace deletes `accounts` after `debt_records`/`subscriptions`. See [[Backup-Format-Specification]] section 7.

## 10. Savings goals (2026-10-18)
Schema v13 adds `savings_goals` and `savings_contributions` as optional extended keys; skip-on-missing-parent on restore; delete order contributions, goals, then expenses and accounts. See [[Backup-Format-Specification]] section 8.

## 11. Committees (2026-10-18)
Schema v14 adds `committees` and `committee_events` as optional extended keys with skip-on-missing-parent and nullable account link; delete order events, committees, then expenses and accounts. See [[Backup-Format-Specification]] section 9.

## Icon files in ZIP backups (2026-10-27)
ZIP backups carry the user's uploaded icons (`icons/uploads/`) and icon edits (`icons/overrides/`). `createBackup(iconFiles:)` writes them; after a successful restore `AppState.restoreJsonBackup` calls `SvgCustomizationService.importFiles` (Safe Merge keeps local files, Full Replace uses the backup copy, unsafe names and invalid SVGs are skipped, and an icon problem never fails the restore). JSON-only and safety backups carry no icons. Details: [[Backup-Format-Specification]] section 10, [[ADR-0007-SVG-Customization-and-Global-Overrides]].
