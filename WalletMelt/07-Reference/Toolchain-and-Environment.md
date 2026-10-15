---
type: reference
status: stable
priority: medium
created: 2026-09-13
updated: 2026-09-13
domain: reference
related:
  - "[[Current-Project-State]]"
  - "[[Build-and-Release-Pipeline]]"
---

# Toolchain and Environment Reference

## 1. Local Development Environment
- **Host OS**: Windows 11
- **Flutter SDK**: `D:\flutter\bin` (Version: 3.44.2 stable)
- **Dart SDK**: Version 3.12.2
- **Android SDK**: Android SDK 36.1.0 (`C:\Users\Hp\AppData\Local\Android\Sdk`)
- **JDK Location**: `D:\AndroidStudioNew\jbr` (Java 21)
- **Test Emulator**: `WalletMelt_API_36` / `emulator-5554` (API 36)

## 2. Essential Commands Cheat Sheet
```powershell
# Dependencies & Analyzer
& "D:\flutter\bin\flutter.bat" pub get
& "D:\flutter\bin\flutter.bat" analyze

# Testing
& "D:\flutter\bin\flutter.bat" test

# Drift Code Generation
& "D:\flutter\bin\flutter.bat" pub run build_runner build --delete-conflicting-outputs

# Build All 5 Release APK Targets (Unified Idempotent Pipeline)
powershell -ExecutionPolicy Bypass -File .\scripts\build_apks.ps1
```

## 3. External Documentation References
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Flutter GoRouter](https://docs.flutter.dev/ui/navigation/deep-linking)
- [Local Auth Plugin](https://pub.dev/packages/local_auth)
- [FL Chart Documentation](https://flchart.dev/)
