# WalletMelt Phase 12B Export/Backup Readiness Plan

## 1. Current Export/Backup Capability Inventory

WalletMelt does not currently have user-facing CSV export, JSON export, local database backup, restore/import, share-sheet export, or export destination selection.

Existing adjacent capabilities:

- Pre-V2 migration database backup exists in `WalletMeltDatabase.createPreV2BackupIfNeeded`. This is migration safety only, not a user backup feature.
- Receipt capture/storage exists through `LocalReceiptStorageService`.
- Settings persistence exists through `SettingsService`.
- `WalletMeltSettings.lastExportedAt` already exists, but no code currently updates it.
- Android permissions currently support camera and image reads for receipts.
- Settings UI explicitly lists backup/restore and export as future scope.

Capability status:

| Capability | Status | Notes |
| --- | --- | --- |
| CSV export | Missing | No export service, writer, UI action, or tests. |
| JSON export | Missing | No backup model, serializer, or backup file writer. |
| Local database backup | Partial internal only | Migration-only SQLite file copy before V2 upgrade. |
| Local database restore | Missing | No user backup restore/import flow. |
| Receipt/file backup | Missing | Receipts are stored locally but not packaged for backup. |
| Share sheet/export destination | Missing | No share or destination picker dependency. |
| Permissions/storage handling | Partial | Camera/media read permissions exist; no export destination strategy. |
| Settings/preferences backup | Partial data only | Settings are persisted but no export/import code exists. |

## 2. Existing Relevant Dependencies

Direct dependencies relevant to export/backup:

- `path`: path construction.
- `path_provider`: app documents/temp directories for generated exports.
- `shared_preferences`: settings storage.
- `sqflite`: legacy SQLite access and database path.
- `drift`, `drift_flutter`, `sqlite3`, `sqlite3_flutter_libs`: Drift-first local database access.
- `image_picker`: receipt image selection/capture.
- `flutter_image_compress`: receipt compression before persistence.

Transitive dependency currently present:

- `archive` appears in `pubspec.lock` as a transitive dependency, likely from tooling. It should not be used from app code unless promoted to a direct dependency in the phase that creates ZIP backups.

## 3. Missing Dependencies, If Any

Phase 13A CSV export can avoid new dependencies by using a pure Dart CSV encoder utility and writing to a temporary/app-documents file.

Later phases likely need:

- `share_plus`: Android share sheet for CSV/backup files.
- `file_picker` or Android Storage Access Framework support: user-selected restore/import file and optional save location.
- `archive`: direct dependency for production ZIP backup creation.

Avoid adding `permission_handler` unless a chosen Android storage strategy requires explicit runtime permissions. For app-private temporary files shared by intent, prefer share-sheet based export that does not require broad storage permissions.

## 4. Data Entities That Must Be Exportable

Minimum CSV export:

- Expenses, including active and optionally deleted rows.
- Category display data joined into expense CSV where useful.
- Receipt URI/path metadata as text only.

Full JSON backup:

- `expenses`
- `grocery_items`
- `expense_items`
- `items`
- `item_aliases`
- `units`
- `stores`
- `categories`
- `category_budgets`
- `receipts`
- `sync_metadata`
- `migration_audit`, for diagnostics only if useful.
- Settings from `SettingsService`: currency, theme preference, onboarding completion, and last export timestamp if appropriate.

Receipt file backup:

- Physical files referenced by `expenses.receiptImageUri`.
- Physical files referenced by `receipts.uri`.
- Metadata for missing receipt files so restore can report incomplete backups.

## 5. Recommended Export Formats

CSV should be the human-readable format for expense export. The recommended expenses CSV columns are:

```text
id,date,title,amount,currency,category_name,vendor,notes,receipt_image_uri,is_recurring,created_at
```

Future itemized CSV exports may use separate files:

- `expenses.csv`
- `grocery_items.csv`
- `expense_items.csv`
- `monthly_summary.csv`
- `annual_summary.csv`
- `item_price_history.csv`

JSON should be the full local backup/restore format. It should preserve table-shaped records closely enough to validate and restore IDs, relationships, soft-deleted rows, and settings.

## 6. Recommended Backup File Structure

Recommended ZIP structure:

```text
walletmelt-backup-YYYYMMDD-HHMMSS.zip
├── metadata.json
├── data/
│   ├── walletmelt-backup.json
│   ├── expenses.csv
│   └── grocery_items.csv
├── database/
│   └── wallet_melt.db
└── receipts/
    ├── <receipt-file-name>.jpg
    └── receipts_manifest.json
```

Minimum metadata:

```json
{
  "app_name": "WalletMelt",
  "app_version": "0.1.1+2",
  "backup_format_version": 1,
  "database_schema_version": 2,
  "export_timestamp": "2026-06-14T00:00:00.000Z",
  "platform": "Android",
  "database_file_name": "wallet_melt.db",
  "receipt_file_count": 0,
  "missing_receipt_file_count": 0
}
```

## 7. Restore Safety Rules

Restore must be a separate phase after export is proven.

Required safety rules:

- Unzip into a temporary directory first.
- Validate `metadata.json` before reading data files.
- Reject missing metadata.
- Reject incompatible `backup_format_version`.
- Reject backup files with `database_schema_version` newer than the app supports.
- Verify JSON shape, required tables, required fields, and foreign-key relationships.
- Verify SQLite backup integrity before replacing or importing from a database file.
- Avoid duplicate imports by preserving IDs when safe and checking existing IDs before insert.
- Do not overwrite active local data without an explicit confirmation step.
- Prefer restore preview first: counts for expenses, categories, budgets, receipts, missing files, and conflicts.
- Keep current data untouched until validation succeeds.
- If using full replacement, close database handles before file swap and replace the SQLite file atomically with sidecar handling.
- If using merge import, perform all writes in a transaction and roll back on any validation/write failure.
- Preserve soft-deleted rows unless the user explicitly chooses active-only import.

## 8. Receipt Handling Strategy

Current receipt files live in the app documents directory under `receipts/`, and database rows store file URIs.

Recommended export behavior:

- Include receipt metadata in JSON from both `expenses.receiptImageUri` and `receipts.uri`.
- Copy existing receipt files into `receipts/` inside the backup ZIP.
- Include `receipts_manifest.json` with original URI, backup relative path, file size, MIME type when known, and missing-file status.
- Do not fail the whole backup for missing receipt files. Mark them as missing and surface the count.

Recommended restore behavior:

- Restore receipt files into the active app documents `receipts/` directory.
- Rewrite restored receipt URIs to new local file URIs.
- Preserve receipt IDs and expense relationships where safe.
- Treat missing files as warnings during import preview, not silent success.

## 9. Android Storage/Share Strategy

Recommended phased strategy:

- Phase 13A: generate CSV into app cache/documents and test the writer only. Do not add UI or storage permissions.
- Phase 13B: add backup ZIP generation into a temporary app-private file.
- Phase 13B or later: add `share_plus` for Android share-sheet export. This avoids broad storage permissions for the initial export path.
- Phase 13C: add file selection for restore only when restore validation is implemented.
- Avoid broad external storage permissions on modern Android unless the selected implementation requires them.

Current Android manifest has:

- `CAMERA`
- `READ_MEDIA_IMAGES`
- `READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"`

No export-specific manifest changes are recommended until the share/import implementation is selected.

## 10. Test Strategy

Phase 13A CSV tests:

- CSV escaping for commas, quotes, line breaks, and null fields.
- Stable column order.
- Active-only and include-deleted export modes if both are supported.
- Category name lookup fallback when a category is missing.
- Receipt URI text preservation.
- No dependency on UI, AppState writes, or platform channels.

Phase 13B JSON backup tests:

- Metadata schema generation.
- Backup JSON includes all required table groups.
- Settings serialize correctly.
- Receipt manifest handles existing and missing files.
- ZIP layout contains expected paths.

Phase 13C restore validation tests:

- Reject missing metadata.
- Reject newer backup format version.
- Reject newer database schema version.
- Reject malformed JSON.
- Reject broken foreign keys.
- Detect duplicate IDs.
- Preview counts without mutating active data.
- Transaction rollback on failed import.

Phase 13D receipt tests:

- Receipt files copied into backup.
- Missing receipt files are reported.
- Restored receipt URIs point to app-local files.
- Existing local receipt filenames do not collide.

Phase 13E runtime QA:

- Manual Android backup/export/share flow.
- Manual restore preview and cancel.
- Manual restore/import into a clean install.
- Data recovery check after app restart.

## 11. Runtime QA Checklist

For CSV export:

- Add sample expenses across multiple categories.
- Add a grocery/itemized expense.
- Add an expense with commas, quotes, and multiline notes.
- Add an expense with a receipt.
- Soft-delete one expense.
- Export CSV.
- Open/share the file and verify headers, row count, formatting, category names, and receipt URI text.
- Restart app and verify no data changed.

For full backup/restore:

- Export backup with categories, budgets, receipts, active expenses, deleted expenses, and grocery items.
- Confirm backup file is created and shareable.
- Inspect ZIP structure.
- Restore preview on a clean install.
- Confirm counts before import.
- Import and restart app.
- Verify dashboard, history, deleted-expense restore, insights, budgets, settings, and receipt previews.
- Attempt incompatible/malformed backup and verify it is rejected without data mutation.

## 12. Risk Analysis

Main risks:

- Drift and sqflite both open the same SQLite file. Restore by file replacement must close all database handles first.
- Full database replacement can invalidate singleton database handles. Restore must define lifecycle ownership before implementation.
- Backup ZIP creation needs WAL/SHM sidecar awareness if copying a live SQLite database. A JSON export from Drift avoids that for logical backup, while raw database backup requires stricter handling.
- Current `DatabaseSchema.currentVersion` is still `1` for the legacy sqflite path while Drift schema is `2`. Backup metadata should use `WalletMeltDatabase.currentSchemaVersion` for the active migrated schema.
- Receipt file URIs are device-local and cannot be reused directly on restore. They must be rewritten.
- The app has no share/import dependencies yet. Adding them should be isolated to the phase that uses them.
- `archive` is currently transitive. Depending on it without declaring it directly would be fragile.
- Settings include `hasCompletedOnboarding`; restore should decide whether restoring settings can skip onboarding on a clean install.

## 13. Recommended Implementation Phases

### Phase 13A - CSV Expense Export Foundation

Scope:

- Add a pure Dart CSV encoder utility.
- Add an expense CSV row builder using domain `Expense` plus category lookup.
- Add tests for escaping, ordering, nullable fields, deleted rows, and category fallback.
- Do not add UI, share sheet, restore, dependencies, or schema changes.

Recommended output:

- `lib/src/services/export/expense_csv_exporter.dart`
- `test/services/expense_csv_exporter_test.dart`

### Phase 13B - Full Local JSON Backup

Scope:

- Add backup metadata model.
- Add Drift read-only backup collector.
- Export table-shaped JSON for all local entities and settings.
- Add ZIP generation only after declaring `archive` as a direct dependency.
- Optionally include CSV files inside the ZIP.
- Add receipt manifest generation.

### Phase 13C - Restore Validation/Import Flow

Scope:

- Add restore validator first, with no mutation.
- Add preview counts and conflict detection.
- Add merge/import or full-replacement strategy after validation tests pass.
- Keep all mutations transactional.
- Add explicit overwrite/merge confirmation before UI integration.

### Phase 13D - Receipt Backup Handling

Scope:

- Copy receipt files into backup ZIP.
- Restore receipt files into app-local receipt storage.
- Rewrite receipt URIs.
- Report missing files.
- Avoid filename collisions.

### Phase 13E - Android Runtime QA and Data Recovery Verification

Scope:

- Test CSV export on emulator.
- Test full backup share flow.
- Test clean-install restore.
- Verify data persists after restart.
- Verify malformed backup rejection.
- Verify no database double-open warning or warning loop.

## 14. Deferred UI/UX Note

The grocery/itemized expense input fields are currently cramped and feel unnatural. This should be scheduled as a later focused UI/UX polish phase for itemized expense entry after the export/backup foundation is in place.

Do not mix the grocery/itemized input redesign into export/backup implementation phases.

