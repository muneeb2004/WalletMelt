# WalletMelt Restore Readiness Plan

This document outlines the design and sequence for a future **Restore/Import** capability for WalletMelt. In alignment with strict safety guidelines, this plan ensures no active database mutation occurs without complete validation, user preview, and explicit confirmation.

---

## 1. Restore Phased Sequence

To ensure safety and robust operation, the restore functionality will be built across five distinct steps:

### Phase 14A — Import File Picker & Parse-Only Validation (Completed)
- **Status:** PASS
- **Objective:** Select a file from the host device and validate its structure.
- **Implemented Features:**
  - Selecting a backup `.json` file from the host device using the platform picker (`file_picker`).
  - Parsing the file content as UTF-8 string and decoding it as JSON.
  - Validating backup structure, format, version compatibility, and required top-level keys using the read-only `WalletMeltJsonBackupValidator`.
  - Extracting statistics/counts (expenses, categories, budgets, and grocery items) from valid backups.
  - Displaying a success summary or a descriptive validation failure message (such as malformed JSON, wrong format, missing keys, etc.) via SnackBar in the settings UI.
- **Exclusions (Still NOT supported in this phase):**
  - Database restore or importing records (no repository/Drift database writes).
  - Import preview UI / comparison screens (to be added in 14B).
  - Mutating local categories, expenses, budgets, grocery items, settings, or receipts.
  - Merging or overwriting conflicts (to be added in 14C).
  - Transactional database write rollback (to be added in 14D).
  - Receipt file extraction or rewriting receipt URIs.

### Phase 14B — Import Preview UI and Read-Only Backup Summary (Completed)
- **Status:** PASS
- **Objective:** Inform the user of what the backup contains before any database operation.
- **Implemented Features:**
  - Designed and implemented a structured `WalletMeltJsonBackupPreviewService` that generates a `WalletMeltBackupPreview` model containing metadata and counts.
  - Implemented a modern dialog UI in `SettingsScreen` showing:
    - **Metadata:** Format, Format Version, App Version, and Exported At timestamp.
    - **Entity counts:** Expenses (Active and Soft-deleted), Grocery Items, Categories, Budgets, and Settings configuration.
    - **Warnings:** Alerts if the backup has warning triggers, such as receipt images referenced but physical files not packaged.
  - Added a non-functional disabled button placeholder for "Restore (N/A)" with explicit warnings that no database mutations are performed.
  - Fully verified using unit and widget test cases.
- **Exclusions (Still NOT supported in this phase):**
  - Database restore or importing records (no repository/Drift database writes).
  - Merging or overwriting conflicts (to be added in 14C).
  - Transactional database write rollback (to be added in 14D).
  - Receipt file extraction or rewriting receipt URIs.

### Phase 14C — Conflict Detection & Duplicate Handling
- **Objective:** Compare backup records against active local records to identify duplicates and conflicts.
- **Actions:**
  - Compare entity IDs in the backup with existing database IDs.
  - Flag exact duplicates (identical ID and matching fields) to be ignored or updated.
  - Detect conflicting records:
    - **Category Name/ID Conflicts:** Category name already exists with a different ID, or Category ID exists with a different name.
    - **Budget Conflicts:** Multiple budgets defined for the same category and month.
    - **Grocery Item Orphans:** Grocery items whose parent `expense_id` does not exist in the active database and is not present in the backup.
  - Formulate merge/overwrite strategies:
    - *Overwrite:* Replace colliding local records with backup data.
    - *Merge/Skip:* Skip duplicates, append non-existing items, and link dependencies.

### Phase 14D — Transactional Restore/Import Mutation
- **Objective:** Execute the database writes safely and atomically.
- **Actions:**
  - Prompt the user with a high-visibility, explicit confirmation dialog warning them of any overrides.
  - Execute all database writes inside a single database Transaction (via Drift's transaction block).
  - Ensure all constraints are verified. If a foreign key constraint or database write fails, roll back the entire transaction.
  - Once successful, clear local app state/caches and reload active providers/Riverpod states to refresh the UI immediately.

### Phase 14E — Android Runtime Data Recovery QA
- **Objective:** End-to-end verification of recovery states on host platforms.
- **Actions:**
  - Conduct manual smoke tests on the Android emulator (`Test_API_36` / `emulator-5554`).
  - Import a known backup file onto a clean install and verify data parity (dashboard counts, category icons/colors, insights charts, budget calculations, settings defaults).
  - Test crash resilience, double-open scenarios, and verify that no duplicate active database handles are created during import recovery.

---

## 2. Key Risks & Mitigation Strategies

| Risk | Impact | Mitigation Strategy |
|---|---|---|
| **Duplicate IDs** | Primary key constraint violations, crash, or data corruption. | Run pre-import scan comparing backup IDs with active database. Use `insertOnConflictUpdate` or filter out existing records during merge. |
| **Category ID Conflicts** | Expenses linked to wrong categories, UI display anomalies. | Match categories by name as fallback. Generate new IDs for categories with duplicate names and rewrite `category_id` in referring expenses. |
| **Budget Month/Category Conflicts** | Double budget allocations for a single month. | Update existing budget amount or warn the user that existing budgets will be overwritten. |
| **Orphaned Grocery Items** | Foreign key constraints block insert, or items exist without parent. | Filter out or reject grocery items whose parent `expense_id` is missing from both the database and the backup. |
| **Soft-deleted Expense Conflicts**| Stale/deleted expenses override newer active data. | Check `updated_at` timestamps. Keep the record with the latest timestamp. |
| **Receipt URI/Path Invalidity** | Missing image warnings, broken UI thumbnail previews. | Mark physical files as missing if they do not exist. In later phases, copy files to `receipts/` directory and update URIs to match the new host path. |
| **Format/App Version Mismatch** | Parsing crashes due to unexpected/new fields. | Reject backups where `format_version` is greater than the current app format version support. |
| **Partial Restore Failure** | Database left in an inconsistent/corrupt state. | Always perform database writes inside a single SQL Transaction, allowing complete rollback on error. |

---

## 3. Implementation Constraints

To preserve stability, future developers must adhere to these hard restrictions:
1. **Never Fail Silently:** If validation fails at any point during parsing or execution, fail loud and revert the transaction.
2. **Explicit User Choice:** Database overwrites must require confirmation. A backup should never overwrite active local database records automatically on load.
3. **Receipt Storage Alignment:** Restoring receipts should align with `LocalReceiptStorageService` configurations.
