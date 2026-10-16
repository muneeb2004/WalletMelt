---
type: convention
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-15
domain: engineering
related:
  - "[[Project-Constitution]]"
  - "[[AI-Engineering-Protocol]]"
---

# Testing Conventions

## 1. Test Verification Commands
- Static Analysis: `& "D:\flutter\bin\flutter.bat" analyze` (Enforces 0 warnings, 0 errors).
- Automated Unit & Widget Tests: `& "D:\flutter\bin\flutter.bat" test`.

## 2. Test Architecture & Rules
- **Pure Unit Tests**: Test models, calculators, and services without widget inflation.
- **Drift In-Memory DB**: Use `WalletMeltDatabase.memory()` in tests to isolate database state without touching platform filesystems.
- **Widget Testing & Async File I/O**:
  - Flutter `testWidgets` isolate scheduling can block if background async file operations occur without pump pumps.
  - When accessing disk caches in services (e.g. `SvgCustomizationService`), provide testing hooks like `setBaseDirForTesting()` and use synchronous file lookups where possible.
- **Mock State**: Use fake or mocked repositories when testing screens to verify UI rendering without dependencies on native platform channels.

## Additions (2026-10-15)
- Heavy cross-domain regression: `test/services/export/backup_v2_roundtrip_test.dart` (seed every table, export v2, restore, compare per-table counts + `PRAGMA foreign_key_check`). Copy this pattern for any new table: add it to `_tables` and `_seed`.
- Renewal/minor-unit regressions: `test/subscription_renewal_test.dart` (injects a failing `DriftExpenseRepository` subclass against a real in-memory DB).
- Long settings lists build lazily: scroll first with the `_reveal` helper in `settings_screen_test.dart` before `ensureVisible`/`expect`.
- `test/screenshots/publication_screenshot_test.dart` rewrites tracked PNGs in `walletmelt_screenshots/` and is slow; exclude it from routine runs and `git checkout -- walletmelt_screenshots` afterwards.
- Run the full suite in the background writing to a file (do not pipe through `Select-Object -Last`, which prints nothing until exit).

## Screenshot tests
- `RepaintBoundary.toImage` and `Image.toByteData` are real engine futures. Always call them inside `tester.runAsync`, otherwise the test never completes. See `test/screenshots/screenshot_harness.dart`.
- Do not run `flutter test` or `flutter analyze` while a release APK build is running: `flutter test` regenerates `GeneratedPluginRegistrant.java` with dev-only plugins (`integration_test`) and breaks the Gradle build.
