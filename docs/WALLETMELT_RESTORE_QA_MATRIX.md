# WalletMelt Restore QA Matrix

This document provides a formal, comprehensive QA matrix covering the entire export, backup, and restore pipeline built across phases 13C through 14I. It maps each capability to automated test coverage and manual Android runtime QA checks to ensure release readiness.

---

## 1. Export QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| CSV Export Trigger | Tap "Export expenses CSV" button on Settings screen. | Service generates CSV file; Android share sheet opens with the CSV file attached. | YES | YES |
| Include-Deleted Toggle (OFF) | Toggle is unchecked. Active expenses exist locally. | Exported CSV file only contains active expenses. | YES | YES |
| Include-Deleted Toggle (ON) | Toggle is checked. Active and soft-deleted expenses exist locally. | Exported CSV file contains both active and soft-deleted expenses. | YES | YES |
| Export Status / Last Exported Date | Complete CSV export or JSON backup successfully. | Settings UI updates the last exported timestamp to display the correct relative time/timestamp. | YES | YES |
| Filename Generation & Formatting | Generate export. | Filename matches standard prefix and timestamp: `walletmelt-expenses-YYYYMMDD-HHMMSS.csv` | YES | YES |
| Filename Collision | Generate multiple exports in quick succession. | Writer appends unique suffix (e.g. `-2`, `-3`) before extension to prevent collision. | YES | NO |

---

## 2. JSON Backup QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| JSON Backup Trigger | Tap "Back up JSON" button on Settings screen. | Service generates JSON backup; Android share sheet opens with the JSON file attached. | YES | YES |
| Field Coverage Verification | Local database has expenses, grocery items, custom categories, budgets, and settings. | Exported JSON covers all these entities with the exact fields specified in the backup format contract. | YES | YES |
| Deterministic Ordering | Export backup multiple times with identical database contents. | Lists of entities (`expenses`, `grocery_items`, `categories`, `budgets`) are sorted deterministically by ID (or other keys), producing identical binary hashes. | YES | NO |
| Receipt Text Preservation | Expense has a receipt image URI (`file:///path/to/receipt.jpg`). | Backup includes the `receipt_image_uri` key as a literal string. | YES | YES |
| Onboarding & Settings | Backup settings block. | Settings object is exported correctly containing currency, theme, onboarding state, and last exported date. | YES | YES |

---

## 3. Validation QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| Valid Backup File | Choose a standard, valid backup file via platform picker. | Validator reports success; UI shows a SnackBar with entity counts and validation success. | YES | YES |
| Malformed JSON File | Pick a corrupted file that is not parseable as JSON (e.g., text file or truncated JSON). | Validator rejects the file gracefully; UI shows a failure SnackBar explaining it is malformed. | YES | YES |
| Unsupported Format | Pick a JSON file that does not have format `walletmelt.local_json_backup` in metadata. | Validator rejects the file; UI shows an unsupported format error SnackBar. | YES | YES |
| Unsupported Format Version | Pick a JSON file with `format_version != 1`. | Validator rejects the file; UI shows an unsupported format version error SnackBar. | YES | YES |
| Picker Cancel | Trigger picker but cancel/dismiss it without selecting any file. | Service returns null safely; UI returns to original settings state without crash. | YES | YES |
| Missing Required Keys | Pick a JSON file missing `metadata`, `expenses`, `grocery_items`, `categories`, `budgets`, or `settings`. | Validator detects the missing key and fails gracefully with a user-safe message. | YES | YES |

---

## 4. Preview QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| Metadata Display | Load a valid backup file. | Preview Dialog displays format version, app version, and exported-at timestamp. | YES | YES |
| Entity Counts | Load a valid backup file. | Preview Dialog lists correct count of expenses (active/deleted), grocery items, categories, and budgets. | YES | YES |
| Receipt Warning | Backup contains expenses with receipt image URIs. | Preview Dialog displays an amber alert warning that receipt physical files are not packaged and will be restored as text-only references. | YES | YES |
| Settings Present Warning | Backup contains settings block but settings import is not selected. | Preview Dialog shows warning that local preferences (currency, theme) will not be affected unless selected. | YES | YES |
| Clean State Preview | Select a valid backup that matches current empty local app state. | Preview Dialog shows the counts and a success summary without warnings or conflict blocks. | YES | YES |

---

## 5. Conflict Detection QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| Expense ID Duplicate | Backup expense ID matches an existing local expense. | Detects duplicate expense ID; adds warning line to conflict section. | YES | YES |
| Custom Category Name Mismatch | Backup custom category has same name but different ID as a local custom category (or vice-versa). | Detects category name/ID mismatch; adds warning line to conflict section. | YES | YES |
| Budget Collisions | Backup budget matches local budget on month + category ID. | Detects duplicate budget month/category; adds warning line to conflict section. | YES | YES |
| Orphaned Grocery Items | Backup grocery item references an expense ID that is not in the backup or local database. | Detects orphaned grocery item; adds blocker warning line. | YES | YES |
| Orphaned Budgets | Backup budget references a category ID not in the backup or local database. | Detects budget category orphan; adds warning line. | YES | YES |
| Clean-State Match | Run conflict detection on empty app database. | Summary reports zero conflicts; UI shows a green "No conflicts detected" check. | YES | YES |
| Settings Diff Detection | Local settings currency/theme differ from backup settings. | Diff warning is generated and shown in the conflict summary. | YES | YES |

---

## 6. Dry-Run QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| Blocker Identification | Backup contains orphaned grocery items or budget month/category collisions. | Planner flags them as blockers, sets `hasBlockers = true`, and sets `canStartFutureMutation = false`. | YES | YES |
| Warnings Classification | Backup has soft-deleted expenses or receipt URIs. | Planner flags them as warnings but does not block restore mutation. | YES | YES |
| ID Remap Proposals (Categories) | Backup category ID collides with local category ID but contents differ. | Planner proposes a deterministic new ID and remaps all budget and expense references to the new ID. | YES | NO |
| ID Remap Proposals (Expenses) | Backup expense ID collides with local expense ID. | Planner proposes a deterministic new ID and remaps grocery item references. | YES | NO |
| Safety Gate Checks | Validate safety gates in the dry-run plan. | Gates verify format, version, preview, conflict review, and ensure explicit confirmation / pre-restore backup remain checked off. | YES | YES |

---

## 7. Restore Gate QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| Blocker Prevents Restore | Dry-run plan contains any blocker (e.g. orphan grocery item or budget collision). | UI disables "Restore" button; preview dialog displays warning that restore is unavailable. | YES | YES |
| Confirmation Cancel | Tap "Restore" -> Confirmation dialog pops up -> Tap "Cancel". | UI closes dialog safely; no database mutation occurs. | YES | YES |
| Safety Backup Creation | Tap "Restore" -> Tap "Confirm" on confirmation dialog. | UI triggers `createBackup` of current data. The restore service verifies the file exists and is non-empty before initiating mutation. | YES | YES |
| Safety Backup Failure | Simulate write/storage failure during safety backup generation. | Restore process aborts immediately; no transaction is started; user sees clear error SnackBar. | YES | YES |
| Drift Database Unavailable | AppState cannot resolve Drift database instance (e.g. db not open). | Restore aborts before transaction starts; fails closed with user-safe error message. | YES | NO |

---

## 8. Safe-Merge Restore QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| Clean Merge | Confirm restore of valid no-blocker backup. | Database transaction runs successfully; insert counts match expected numbers; SnackBar displays success message with safety backup filename. | YES | YES |
| Local Preservation | Execute restore. | Local expenses, categories, budgets, and grocery items remain completely intact; no local data is overwritten or replaced. | YES | YES |
| Receipt Text Restoration | Execute restore of expense with receipt URI. | Target expense is inserted with its `receipt_image_uri` text intact; SnackBar warns that receipt files themselves are not copied. | YES | YES |
| AppState Refresh | Safe-merge commit completes. | AppState triggers refresh immediately after commit; UI updates and refreshes Dashboard, History, and Insights. | YES | YES |
| Transaction Rollback | Simulate insert failure mid-transaction (e.g., category mapping exception). | Database rolls back completely; no partial inserts commit; AppState does not refresh; user gets clear error message. | YES | NO |
| Relation Integrity Verification | Simulate relationship loss before commit (e.g., orphaned expense category ID). | Post-restore validation triggers rollback; database remains unmodified. | YES | NO |

---

## 9. Regression QA

| Test Case | Input / Precondition | Expected Result | Automated | Runtime |
|---|---|---|---|---|
| Drift Double-Open Prevention | Launch app and run backup/restore. | Database uses the shared Drift handle provided by AppState; no double-open database warning in console. | YES | YES |
| MissingPluginException Check | Tap CSV export or JSON backup actions. | Share sheet resolves correctly on Android without throwing MissingPluginException. | YES | YES |
| Crash Loop Absence | Perform sequence of validation, preview, cancel, and restore. | Application remains responsive and stable; no crash loop or ANR observed. | YES | YES |
| Idempotent Drift Migration | Replay Drift V1-to-V2 migrations on partially migrated db. | Migration replay ignores already-created V2 tables/columns instead of failing; database opens stably. | YES | YES |
| KGP Warnings Non-blocking | Observe Kotlin Gradle Plugin compiler warnings. | App builds and launches successfully despite warnings for `share_plus` and `flutter_image_compress_common`. | YES | YES |

---

## 10. Explicitly Out-of-Scope Behaviors

The following features are **explicitly out-of-scope** and are deferred as future work:

| Deferred Feature | Rationale for Exclusion | Future Implementation Path |
|---|---|---|
| Full Replace Restore | Violates the safety boundary of preserving existing local data. | Requires dedicated "destructive restore" warning dialogs, force-delete operations, and different safety gates. |
| Auto-Overwrite Conflicts | Dangerous silent data loss of local custom category names or budgets. | Requires a dedicated Conflict Resolution UI allowing users to choose "Keep Local" vs "Overwrite" for each collision. |
| Receipt File Copying | Backup is text-only JSON. Media files are too large and complex to manage without separate permissions. | Requires wrapping the database and media folder in a `.zip` archive or binary container. |
| Cloud Backup | WalletMelt is designed as a local-first application with no server dependencies. | Requires setting up auth, backend API integration, and cloud sync services. |
| ZIP / Tarball Backup | Standard JSON backup meets portability needs; ZIP increases binary size and complexity. | Future work under a different metadata format version. |
