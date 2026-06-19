# WalletMelt Release Readiness Gate

This document serves as the formal Release Readiness Gate for the export, backup, and restore feature set of WalletMelt (Phases 13C through 14I). It verifies that all boundaries, invariants, and quality metrics have been met at Phase 14J.

---

## 1. Feature Scope

### Shipped Features
- **CSV Expense Export:** Generates CSV exports from Settings with a checkbox toggle for including soft-deleted expenses. Displays the last exported timestamp in relative format.
- **JSON Backup Generation:** Exports expenses, soft-deleted expenses, grocery items, categories, budgets, and settings configuration in a deterministically ordered JSON structure.
- **Backup Verification & Parser:** Parse-only validation checking metadata format, versions, top-level keys, and extracting entity counts without triggering any database write.
- **Read-Only Backup Preview:** Displays formatted metadata (app version, format version, timestamp), counts, and warning flags in a custom dialog.
- **Conflict & Risk Detection:** Read-only detection showing duplicate expense/category IDs, category name/ID mismatches, duplicate budget month/category pairs, settings differences, and receipt reference counts.
- **Dry-Run Planner:** Synthesizes conflict results and JSON data into a dry-run report. Classifies blockers versus warnings, creates proposed ID mappings, and tests safety gates.
- **Safe-Merge Restore Service:** Writes missing database rows under a single Drift transaction. Preserves all local data, applies dry-run remapping tables, verifies relationship integrity before commit, refreshes state, and fails closed.
- **UX Recovery & Safety:** Requires explicit user confirmation, enforces pre-restore safety backups, blocks restore when blockers exist, hides stack traces from user logs, and secures inputs.
- **Idempotent Migrations:** Guards the Drift database v1-to-v2 schema replay process to be tolerant of incomplete migrations.

### Explicitly Deferred Features
- **Full Replace Restore:** Not supported to prevent data loss.
- **Silent Overwrite:** No silent merging or replacing of budget/category collisions.
- **Manual Conflict Resolution UI:** Selective override, custom name choice, or budget collision choice screens are deferred.
- **Receipt Media Extraction:** Receipt files are not packaged, extracted, or rewritten.
- **ZIP/Archive Backup:** Packaging media assets in binary container files is deferred.
- **Cloud Integration:** Syncing or backing up to external servers is deferred.

---

## 2. Architecture Invariants

Across all phases, the following codebase boundaries were strictly preserved:
1. **Provider/AppState Architecture:** The UI interacts solely with `AppState` for export and restore actions. The Settings screen does not consume database handles directly.
2. **Drift Database Isolation:** All transactional restore mutations occur within a single database transaction via the shared Drift runtime handle owned by `AppState`, preventing double-open warnings.
3. **Sqflite Fallback Preservation:** The sqflite fallback path remains intact and unchanged for standard read/write queries if Drift fails.
4. **No Riverpod Screen Migration:** Standard screens continue to use `Provider` and `AppState` for consistency.
5. **No Schema Changes:** The Drift schema was not changed, and no generated `.g.dart` files were edited manually.
6. **Safe-Merge Mutation Only:** Writes are additive-only and remap IDs deterministic-ally to safeguard existing local records.

---

## 3. Dependency State

All required packages are locked to stable versions in `pubspec.yaml`:
- **Drift Database Layer:** `drift: ^2.34.0`, `drift_flutter: ^0.3.0`, `sqlite3: ^3.3.3`, `sqlite3_flutter_libs: ^0.6.0+eol`.
- **System Utilities & File Access:** `file_picker: ^12.0.0-beta.5`, `share_plus: ^13.1.0`, `path_provider: ^2.1.4`, `path: ^1.9.0`.
- **Core Framework:** Dart SDK `sdk: ">=3.3.0 <4.0.0"`, Flutter SDK, `provider: ^6.1.2`, `flutter_riverpod: ^3.3.2`.

> [!NOTE]
> Gradle compilation displays minor Kotlin Gradle Plugin (KGP) warnings for `share_plus` and `flutter_image_compress_common` due to upstream build configurations. These compiler warnings are non-blocking and have zero runtime impact.

---

## 4. Verification Gate Results

Verification command checklist run at Phase 14J:

| Command | Status | Outcome / Details |
|---|---|---|
| `flutter pub get` | PASS | Dependencies successfully fetched. |
| `flutter pub outdated --show-all` | PASS | Outdated packages inspected. Overrides and locks are correct. |
| `flutter analyze` | PASS | Static analysis passes with zero warnings or lint errors. |
| `flutter test` | PASS | All **224 tests** passed successfully. |
| `flutter build apk --debug` | PASS | Debug Android build compiles successfully. |
| `flutter build apk --release` | PASS | Release production Android build compiles successfully. |

---

## 5. Runtime QA Summary

Verified on Android emulator `Test_API_36` (Device ID: `emulator-5554`):

- **App Initialization:** Boots safely with WalletMelt icon and dashboard. No double-open or sqlite crashes observed.
- **Export Flow:** Checking "Include deleted expenses" and tapping CSV/JSON actions successfully triggers the Android share sheet. Relative timestamps update accurately.
- **Validation Flow:** Picking an invalid or malformed JSON yields a SnackBar warning. Dismissing the file picker returns safely with no crash.
- **Preview & Dry-run:** Valid backups open the preview dialog, displaying format info, entity counts, warning blocks, and dry-run summaries.
- **Safe-Merge Execution:** 
  - Restoring with blockers correctly disables the restore button.
  - Blocker-free plans enable the "Safe merge" button, triggering the confirmation dialog.
  - Cancelling the confirmation closes the dialog with zero data mutations.
  - Confirming safe merge creates a pre-restore backup first (verified size > 0 bytes).
  - Merged entities are written inside one database transaction.
  - If a transaction succeeds, counts refresh in AppState, and the SnackBar shows the backup filename.
  - Local database rows and references remain preserved. Receipt image URIs are kept as text references.
- **Post-Restore Smoking:** Dashboard, History, and Insights reload and calculate correctly. No MissingPluginException or loop crashes observed.

---

## 6. Known Limitations

- **Receipt URI References Only:** Backup JSON only saves the text URI string (e.g. `file:///...`). If the file is missing from the local storage of the device, it will not resolve.
- **No Force Overwrites:** Safe merge will skip duplicate budgets and fail closed on custom category conflicts instead of replacing them.
- **No Cloud Synchronization:** Backups must be manually selected or saved to external storage via the share sheet.

---

## 7. Future Work

- **Selective Import Resolution:** Add a dedicated resolution UI to let users choose whether to rename, merge, or overwrite custom categories and budget collisions.
- **Compressed Media Archiving:** Build a ZIP packaging utility to archive receipt files along with the database JSON backup.
- **Automated Cloud Backup:** Connect backup streams to Google Drive or iCloud APIs.

---

## 8. Recommended Commit Message

```
build: complete phase 14j restore qa matrix and release readiness gate

- Createdocs/WALLETMELT_RESTORE_QA_MATRIX.md covering detailed QA test cases.
- Create docs/WALLETMELT_RELEASE_READINESS.md containing architectural invariants and results.
- Verify that flutter analyze and all 224 tests pass successfully.
- Verify debug and release builds compile on Windows/Android target.
```
