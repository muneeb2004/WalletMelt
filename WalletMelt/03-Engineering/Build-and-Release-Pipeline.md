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
