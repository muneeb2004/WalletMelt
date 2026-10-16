---
type: convention
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-15
domain: engineering
related:
  - "[[Project-Constitution]]"
  - "[[ADR-0006-Standardized-Five-Target-APK-Pipeline]]"
---

# Build and Release Pipeline

## 1. Versioning Protocol
- Version number is declared in `pubspec.yaml` following SemVer (`MAJOR.MINOR.PATCH+BUILD`).
- Every release or major milestone must bump the version and build number prior to running build commands.

## 2. Standardized APK Build Rule (`AGENTS.md`)
Whenever building APKs, the pipeline must compile all 5 target artifacts:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_apks.ps1
```

### Generated Artifact Deliverables:
1. **Production Universal Release APK**: `build/app/outputs/flutter-apk/app-production-release.apk`
2. **Production Split arm64-v8a**: `build/app/outputs/flutter-apk/app-arm64-v8a-production-release.apk`
3. **Production Split armeabi-v7a**: `build/app/outputs/flutter-apk/app-armeabi-v7a-production-release.apk`
4. **Production Split x86_64**: `build/app/outputs/flutter-apk/app-x86_64-production-release.apk`
5. **Screenshots Release APK**: `build/app/outputs/flutter-apk/app-screenshots-release.apk` (pre-seeded with `SCREENSHOT_MODE=true`)

## 3. Windows Gradle Compilation Invariants
`android/gradle.properties` must maintain:
```properties
kotlin.incremental=false
kotlin.compiler.execution.strategy=in-process
org.gradle.parallel=false
```
*(Prevents Windows cross-drive file lock collisions during Flutter/Kotlin builds).*

> Clarification (2026-10-15): the pipeline runs **3 Gradle invocations** (universal, split-per-ABI, screenshots) producing **5 APKs**; scripts also clear `*.apk` and `build/app/intermediates` first, and copy production APKs to legacy `app-*-release.apk` names.

## 4. Single Source of Truth for Version (2026-10-16)
`pubspec.yaml` `version:` is the only place the version is edited. `lib/src/constants/app_version.dart` (`AppVersion`, shown in Settings, the What's New trigger/title and backup metadata) is **generated** from it by `scripts/sync_version.ps1` (`.sh` twin), which both `build_apks` scripts run first. Previously `AppVersion` was a hand-edited copy, so APKs carried the new `versionName` while the in-app UI stayed on the old version. A bare `flutter build apk` skips the sync; run `scripts/sync_version.ps1` first or use the build scripts. The "Version X Highlights" headings use `AppVersion.version`, but the changelog item text is still hand-written per release.

## Concurrency warning (2026-10-17)
Run nothing else that invokes the Flutter tool (`flutter test`, `flutter analyze`, `flutter pub get`) while `build_apks` runs; a concurrent run regenerated `GeneratedPluginRegistrant.java` with `integration_test` and failed the production release compile. Re-run the build after fixing.
