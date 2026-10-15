---
type: convention
status: stable
priority: high
created: 2026-09-13
updated: 2026-09-13
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
