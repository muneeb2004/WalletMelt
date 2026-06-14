# WalletMelt Restore Readiness Plan

This document outlines the design and sequence for a future **Restore/Import** capability for WalletMelt. In alignment with strict safety guidelines, this plan ensures no active database mutation occurs without complete validation, user preview, and explicit confirmation.

---

## 1. Restore Phased Sequence

To ensure safety and robust operation, the restore functionality will be built across staged, independently verified steps:

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
  - Transactional database write rollback execution (planned after dry-run preconditions).
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
  - Transactional database write rollback execution (planned after dry-run preconditions).
  - Receipt file extraction or rewriting receipt URIs.

### Phase 14C — Read-Only Conflict Detection and Duplicate Handling Plan (Completed)
- **Status:** PASS
- **Objective:** Compare backup contents against current local app data to produce a read-only conflict/risk summary. No mutation was performed in this phase.
- **Implemented Features:**
  - Designed and implemented `WalletMeltJsonBackupConflictService` (read-only, no repository access).
  - Introduced `LocalAppSnapshot` — a plain data transfer object carrying current in-app data supplied by the caller. The service never calls any database or repository APIs.
  - Introduced `BackupConflictSummary` — a structured, immutable result model with counts and optional warning strings.
  - **Expense conflicts detected:**
    - Duplicate expense IDs already present in local data (active or soft-deleted).
    - Soft-deleted expense records present in the backup (counted separately).
    - `receipt_image_uri` references in backup expenses (paths may not exist on this device).
  - **Category conflicts detected:**
    - Duplicate category IDs already present locally.
    - Same category name with different ID (case-insensitive match).
    - Same category ID with different name.
  - **Budget conflicts detected:**
    - Same `month` + `category_id` pair already exists locally (would collide on restore).
    - Budget references a `category_id` not present anywhere in the backup itself (orphaned reference).
  - **Grocery item conflicts detected:**
    - Grocery item `expense_id` not found in either the backup's expense list or local data (orphan).
  - **Metadata / settings warnings:**
    - `app_version` is null or empty → informational warning only.
    - Backup `settings` block is absent → warning that local settings will be unaffected.
    - Backup settings currency or theme differs from current local settings → diff warning.
  - Extended the read-only preview dialog in `SettingsScreen` with a **Conflict check** section:
    - Shows a green "No conflicts detected" message when the backup is clean.
    - Shows amber warning lines for each detected conflict/risk.
    - Displays "Restore is not available yet. No data has been imported or changed."
    - Conflict detection failure is non-blocking; the preview dialog still opens.
  - `BackupConflictSummary.summaryLines` produces human-readable lines for all categories.
  - Added 25 focused unit tests covering all detection categories, clean baseline, summaryLines, malformed JSON handling, and the no-mutation contract.
  - Added 4 widget tests covering conflict display, no-conflict display, detection failure resilience, and disabled Restore button.
  - `Restore (N/A)` button remains disabled and no mutation path exists.
- **Exclusions (Still NOT supported in this phase):**
  - Database restore or importing records (no repository/Drift database writes).
  - Overwrite/merge conflict resolution execution (still future work).
  - Automatic duplicate resolution or ID remapping.
  - Transactional database write rollback execution (still future work).
  - Receipt file extraction or rewriting receipt URIs.

### Phase 14D — Restore Transaction Design and Rollback Planning (Completed)
- **Status:** PASS
- **Objective:** Define the future transactional restore/import design without implementing any database mutation.
- **Implemented Features:**
  - Added `WALLETMELT_RESTORE_TRANSACTION_DESIGN.md` with the future restore transaction sequence, rollback strategy, ID strategy, duplicate handling, receipt URI handling, settings strategy, safety gates, failure cases, and QA matrix.
  - Added pure, inert restore-plan contract models in `wallet_melt_json_restore_plan.dart`.
  - Added tests for restore modes, safety gates, settings optionality, unsupported full replace, blocker handling, and ordered future transaction steps.
  - Clarified the recommended first mutation mode: explicit-confirmed safe merge or sandboxed import, not full replace.
  - Kept Settings restore UI unchanged with `Restore (N/A)` disabled.
- **Still Excluded:**
  - Restore execution.
  - Database import.
  - Merge or overwrite mutation.
  - ID remapping execution.
  - Rollback execution.
  - Transaction code.
  - Receipt recovery.
  - Receipt URI rewriting.

### Phase 14E — Restore Dry-Run Planner and Transaction Preconditions (Completed)
- **Status:** PASS
- **Objective:** Convert validation, preview, and conflict results into a non-mutating dry-run restore plan.
- **Implemented Features:**
  - Added `WalletMeltJsonRestoreDryRunPlanner`, a pure read-only planner that accepts backup JSON and a caller-supplied `LocalAppSnapshot`.
  - Produces proposed future actions for categories, expenses, grocery items, budgets, settings, and receipt references.
  - Produces proposed ID mappings without executing them.
  - Preserves IDs when safe, proposes deterministic replacement IDs for safe merge collisions, and rewrites planned references in memory only.
  - Classifies blockers versus warnings for unresolved category ambiguity, orphaned grocery items, unresolved budget categories, budget month/category collisions, soft-deleted expenses, settings differences, and receipt URI references.
  - Reports safety gate status for supported format, supported version, generated preview, reviewed conflict summary, explicit confirmation, pre-restore backup, transaction runtime, and unresolved blockers.
  - Extended the existing read-only preview dialog with a compact `Dry-run restore plan` summary.
  - Kept `Restore (N/A)` disabled and did not add any restore execution path.
- **Still Excluded:**
  - Restore execution.
  - Database import.
  - Merge or overwrite mutation.
  - ID remapping execution.
  - Rollback execution.
  - Transaction code.
  - Receipt recovery.
  - Receipt URI rewriting.
  - Settings import execution.

### Phase 14F — Transactional Restore/Import Mutation Candidate
- **Objective:** Execute database writes safely and atomically only after dry-run planning is complete and no unresolved dry-run blockers remain.
- **Actions:**
  - Prompt the user with a high-visibility, explicit confirmation dialog warning them of any overrides.
  - Create and verify a pre-restore safety backup.
  - Execute selected database writes inside a single transaction.
  - Roll back the transaction if any constraint, remap, count, or write check fails.
  - Refresh AppState only after commit succeeds.

### Phase 14G — Android Runtime Data Recovery QA
- **Objective:** End-to-end verification of recovery states on host platforms after mutation exists.
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
