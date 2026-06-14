---
name: testing_skill
description: Procedures for running lints, tests, repository verification, migration assertions, and Android build outputs.
---

# WalletMelt Testing Skill

## Test Suite Execution
- **Run Static Analysis:**
  ```powershell
  flutter analyze
  ```
  Ensure all warnings, lints, and errors are resolved.
- **Run All Tests:**
  ```powershell
  flutter test
  ```
  Runs all unit and widget tests defined in the `test/` directory.

## Writing Provider & Repository Tests
- **Riverpod Provider Harness:** Test providers by overriding their dependencies (e.g., database or repositories) using mock or test databases inside a `ProviderContainer` to avoid side effects.
- **SQLite Test Databases:** Initialize temporary, in-memory databases (using Drift's NativeDatabase or sqflite's database factory) for testing repository methods.
- **CRUD Operations:** Verify that created objects match expected domain representations, updating fields works as expected, and queries filter correctly.

## Database Migration Tests
- **V1 Fixture Upgrades:** Verify that a V1 database file is successfully upgraded to the V2 schema, and that all data (categories, budgets, expenses, and receipt attachments) is correctly migrated.
- **Data Validation:** Ensure that totals (e.g. sums of expenses) before and after migration are identical.

## Android Build Verification
- **Verify Compile Targets:** Ensure that changes do not break Android native builds. Test compile steps:
  ```powershell
  flutter build apk --debug
  ```
  and:
  ```powershell
  flutter build apk --release
  ```
- **File Validation:** Document and verify that generated APK files are saved to `build/app/outputs/flutter-apk/app-debug.apk` or similar, recording file path and size.

## Hard Rules
- Automated verification PASS (linter and unit tests) does not equal Android runtime QA PASS.
- Android runtime QA remains PENDING until the app is confirmed running on a device or emulator.
- Always check test counts before and after database modifications, reporting counts explicitly.
