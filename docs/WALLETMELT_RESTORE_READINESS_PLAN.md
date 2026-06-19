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

### Phase 14F — Transactional Restore/Import Mutation Candidate (Completed)
- **Status:** PASS
- **Objective:** Implement the first tightly gated restore mutation path as safe merge only.
- **Implemented Features:**
  - Added `WalletMeltJsonRestoreService` for safe-merge restore execution.
  - Added explicit `WalletMeltJsonRestoreOptions` and structured `WalletMeltJsonRestoreResult`.
  - Added a narrow `AppState.restoreJsonBackupSafeMerge` gateway so Settings does not become a direct database write consumer.
  - Reuses the AppState-owned Drift database runtime for restore transactions and fails closed if that runtime is unavailable.
  - Requires validated JSON, preview generation, conflict review, a no-blocker dry-run plan, explicit user confirmation, and a verified non-empty pre-restore safety backup before any database write.
  - Uses the existing JSON backup path to create a current-data safety backup before mutation starts.
  - Executes category, expense, grocery item, budget, and optional settings merge behavior through one Drift transaction for database entities.
  - Preserves local data by default; no local expenses, categories, budgets, grocery items, settings, or receipt paths are overwritten silently.
  - Applies dry-run ID mappings for duplicate category, expense, grocery item, and budget IDs.
  - Preserves `receipt_image_uri` values as text-only references and records a warning; receipt files are not copied or recovered.
  - Inserts restored grocery rows into `grocery_items` and mirrors them into `expense_items` without creating canonical `items` records.
  - Blocks restore when dry-run blockers remain, including orphaned grocery items and budget month/category collisions.
  - Refreshes AppState only after the restore service reports a successful transaction commit.
  - Replaces `Restore (N/A)` with an enabled `Safe merge` action only for valid no-blocker plans; otherwise restore remains disabled.
  - Adds a high-visibility confirmation dialog explaining safe merge, preserved local data, ID remapping, receipt limitations, and safety backup creation.
- **Still Excluded:**
  - Full replace restore.
  - Overwrite-local-data restore.
  - Silent merge.
  - Conflict-resolution UI for budget/category ambiguity.
  - Receipt file packaging, copying, recovery, or URI rewriting.
  - Settings import option in the Settings UI; the service supports explicit settings import but the UI keeps it off.
  - ZIP/archive restore.

### Phase 14G — Android Runtime Data Recovery QA and Restore Hardening (Completed)
- **Status:** PASS. Code hardening, automated coverage, APK builds, and Android runtime QA completed on `Test_API_36` / `emulator-5554`.
- **Objective:** Stabilize safe-merge restore behavior after the first mutation implementation through focused defensive checks, edge-case tests, and runtime QA planning.
- **Implemented Hardening:**
  - Dry-run planning now fails closed for duplicate-heavy backup content:
    - duplicate category IDs,
    - duplicate category names,
    - duplicate expense IDs,
    - duplicate grocery item IDs,
    - duplicate budget IDs,
    - duplicate budget `month + category_id` pairs.
  - Restore service repeats duplicate-heavy backup preflight checks, so direct service callers cannot bypass the planner with a stale or forged dry-run plan.
  - Restore transaction verifies inserted relationships before commit:
    - every inserted expense category resolves,
    - every inserted grocery item parent expense resolves,
    - every inserted budget category resolves.
  - Relationship verification failure rolls back the transaction.
  - Settings import remains off by default and is only applied when `WalletMeltJsonRestoreOptions.importSettings` is explicitly true.
  - `AppState.restoreJsonBackupSafeMerge` still refreshes AppState only after successful restore service completion.
  - Production restore still fails closed if AppState cannot provide a Drift database runtime.
  - Settings validation/restore controls are disabled while a restore is in progress to prevent double-submit restore attempts.
  - Drift V1-to-V2 migration replay now tolerates partially applied V2 tables/columns when `PRAGMA user_version` is stale, preventing duplicate-column failure during restore runtime startup.
- **Automated Test Coverage Added/Extended:**
  - Safe merge into empty local data.
  - Safe merge into non-empty local data with duplicate expense ID remapping.
  - Duplicate-heavy backup blockers.
  - Duplicate categories by ID/name.
  - Duplicate expenses by ID.
  - Soft-deleted expense import remains soft-deleted.
  - Grocery items remap to remapped expense IDs.
  - Orphan grocery item fails closed.
  - Budget month/category collision fails closed without overwrite.
  - Settings remain unchanged by default.
  - Settings import runs only when explicitly enabled.
  - Receipt URI/path text survives restore and is warned as text-only.
  - Missing/empty safety backup aborts before transaction.
  - Drift runtime unavailable aborts before mutation at the AppState boundary.
  - Transaction rollback on simulated mid-restore failure.
  - Relationship verification rollback on simulated pre-commit relationship loss.
  - AppState refresh occurs after success and not after failure.
  - Invalid backup cannot trigger restore.
  - Dry-run blockers cannot trigger restore.
  - Confirmation cancel causes no mutation in Settings widget tests.
- **Runtime QA Completed (`Test_API_36` / `emulator-5554`):**
  - Clean install launched with an empty dashboard.
  - Clean Settings JSON backup opened the Android share sheet and returned stable.
  - Valid backup preview opened, including metadata, contents, conflict/risk warnings, dry-run restore plan, and enabled safe-merge action.
  - Malformed JSON selection failed gracefully with an invalid-backup SnackBar.
  - Cancelled picker returned to Settings without crash.
  - Restore confirmation cancel returned to Settings without mutation.
  - Confirmed safe merge created a pre-restore safety backup before mutation.
  - Confirmed clean safe merge committed 1 expense, 1 grocery item, 1 category, and 1 budget.
  - Dashboard, History, and Insights refreshed after successful commit.
  - Receipt URI text survived restore as a text reference; no receipt file was copied or rewritten.
  - Old/inconsistent emulator state reproduced a stale `user_version` migration failure, failed closed before mutation, then passed after the idempotent migration guard.
  - No `MissingPluginException`, Drift double-open warning, warning loop, or runtime crash loop was observed in filtered logs.
  - Duplicate-ID remap in a non-empty app remains covered by service/widget tests; runtime manual duplication was not repeated because the clean restore and stale-migration recovery were the higher-risk emulator paths.
- **Still Excluded:**
  - Full replace restore.
  - Overwrite restore.
  - Silent conflict resolution.
  - ZIP/archive backup or restore.
  - Receipt file packaging, copying, recovery, or URI rewriting.
  - Cloud backup.
  - Broad storage permissions.
  - Broad Settings redesign.
  - Drift schema changes or database migrations.

### Phase 14H — Restore UX Polish and Recovery Messaging (Completed)
- **Status:** PASS. Restore UX messaging, automated Settings coverage, APK builds, and Android runtime QA completed on `Test_API_36` / `emulator-5554`.
- **Objective:** Improve the user-facing safe-merge restore experience without changing restore scope or adding new restore modes.
- **Implemented UX Polish:**
  - Validation success now clearly states that the backup is valid, lists preview counts, and confirms no data has been imported.
  - Preview copy now explains safe merge in plain language:
    - safe merge is only available after confirmation,
    - existing local data is preserved,
    - receipt files are not recovered.
  - Blocker copy now states that restore is unavailable until blockers are resolved and WalletMelt will not resolve conflicts automatically.
  - Dry-run copy now distinguishes blockers from pending safety gates and keeps the dry-run-only status visible.
  - Confirmation dialog now explicitly covers safe merge, local preservation, duplicate ID remapping, safety backup creation, and receipt limitations.
  - Restore action text shows `Restoring...` while a restore is running, and validation/restore actions remain disabled during restore.
- **Implemented Recovery Messaging:**
  - Restore success now reports inserted expense, grocery item, category, and budget counts.
  - Restore success mentions the safety backup filename when available.
  - Restore success states local data was preserved and receipt paths remain text-only references.
  - Restore failure now uses a user-safe message that avoids stack traces and explains that transaction rollback prevents partial import state.
  - Restore failure mentions whether a safety backup was reported.
  - Safety-backup creation failure now clears older validation SnackBars and immediately explains that restore did not start and no data changed.
- **Automated Test Coverage Added/Extended:**
  - Success message includes inserted counts and safety backup filename.
  - Failure message is user-safe and does not expose stack traces.
  - Safety-backup creation failure message is clear and non-technical.
  - Blockers disable restore and show the reason.
  - Restore-in-progress disables validation action.
  - Confirmation dialog copy mentions safe merge, local preservation, safety backup, and receipt limitations.
  - Confirmation cancel still causes no mutation.
  - Invalid backup and malformed JSON messaging remain graceful.
  - Restore success still refreshes only after commit through the existing AppState tests.
- **Runtime QA Completed (`Test_API_36` / `emulator-5554`):**
  - App launched, Dashboard loaded, and Settings opened.
  - Existing CSV export and JSON backup actions still opened the Android share sheet and returned stable.
  - Validate backup action remained visible.
  - Valid backup preview opened with conflict/risk and dry-run sections.
  - Confirmation wording was reviewed before safe merge.
  - Confirmation cancel caused no data change.
  - Confirmed safe merge created a pre-restore safety backup first and imported only safe records.
  - Success message showed inserted counts and local-data preservation/receipt text-reference messaging.
  - Malformed JSON failed gracefully with a non-technical invalid-backup message.
  - Cancelled picker returned to Settings without crash.
  - Dashboard, History, and Insights refreshed after successful commit.
  - No `MissingPluginException`, Drift double-open warning, warning loop, or runtime crash loop was observed in filtered logs.
  - Blocker disabled-copy and restore-in-progress disabled-action behavior were covered by widget tests; no additional manual blocker backup was created during runtime QA.
- **Still Excluded:**
  - Full replace restore.
  - Overwrite restore.
  - Conflict resolution UI or conflict resolution execution.
  - Manual ID remapping UI.
  - Receipt file packaging, copying, recovery, or URI rewriting.
  - ZIP/archive backup or restore.
  - Cloud backup.
  - Broad storage permissions.

---

## 2. Key Risks & Mitigation Strategies

| Risk | Impact | Mitigation Strategy |
|---|---|---|
| **Duplicate IDs** | Primary key constraint violations, crash, or data corruption. | Run dry-run planning before restore and apply deterministic safe-merge ID mappings inside the transaction. |
| **Category ID Conflicts** | Expenses linked to wrong categories, UI display anomalies. | Map equivalent/default-like categories only when dry-run marks them safe; otherwise generate a new ID or block ambiguity. |
| **Budget Month/Category Conflicts** | Double budget allocations for a single month. | Block safe merge when a local month/category budget already exists; do not overwrite local budgets. |
| **Orphaned Grocery Items** | Foreign key constraints block insert, or items exist without parent. | Filter out or reject grocery items whose parent `expense_id` is missing from both the database and the backup. |
| **Soft-deleted Expense Conflicts**| Deleted backup rows could be restored as active by mistake. | Preserve `deleted_at` exactly; imported soft-deleted expenses remain soft-deleted. |
| **Receipt URI/Path Invalidity** | Missing image warnings, broken UI thumbnail previews. | Preserve URI text only and warn. Do not copy files or rewrite URIs in JSON safe merge. |
| **Format/App Version Mismatch** | Parsing crashes due to unexpected/new fields. | Reject backups where `format_version` is greater than the current app format version support. |
| **Partial Restore Failure** | Database left in an inconsistent/corrupt state. | Always perform database writes inside a single SQL Transaction, allowing complete rollback on error. |

---

## 3. Implementation Constraints

To preserve stability, future developers must adhere to these hard restrictions:
1. **Never Fail Silently:** If validation fails at any point during parsing or execution, fail loud and revert the transaction.
2. **Explicit User Choice:** Database overwrites must require confirmation. A backup should never overwrite active local database records automatically on load.
3. **Receipt Storage Alignment:** JSON safe merge preserves receipt URI text only. Receipt file packaging or URI rewriting requires a future, separate archive format and explicit design.
