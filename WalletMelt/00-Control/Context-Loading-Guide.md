---
type: guide
status: stable
priority: high
created: 2026-09-13
updated: 2026-09-13
domain: control
related:
  - "[[Project-Constitution]]"
  - "[[AI-Engineering-Protocol]]"
  - "[[Current-Project-State]]"
---

# Context Loading Guide

To minimize context window saturation and eliminate token waste, AI agents must load only the specific documentation chain required for the task.

```text
Hierarchy of Entry:
1. 00-Control/Project-Constitution.md (Always read)
2. 00-Control/Current-Project-State.md (Always read)
3. Task-Specific Domain Chain (Select below)
```

---

## Task-Specific Context Paths

### 1. Financial Analytics / Math / Metric Change
1. `00-Control/Project-Constitution.md`
2. `00-Control/Current-Project-State.md`
3. `01-Product/Product-Requirements.md`
4. `02-Architecture/Analytics-and-Calculations.md`
5. `04-Decisions/ADR-0008-Deterministic-Financial-Metrics-Engine.md`
6. *Related Code*: `lib/src/analytics/`, `lib/src/screens/settings/metric_calculations_screen.dart`

### 2. UI / Screen / Icon / Styling Change
1. `00-Control/Project-Constitution.md`
2. `00-Control/Current-Project-State.md`
3. `01-Product/Design-System-and-UX.md`
4. `03-Engineering/Flutter-Conventions.md`
5. `04-Decisions/ADR-0007-SVG-Customization-and-Global-Overrides.md`
6. *Related Code*: `lib/src/screens/`, `lib/src/components/`, `lib/src/theme/`

### 3. Database / Drift / Schema / Repository Change
1. `00-Control/Project-Constitution.md`
2. `00-Control/Current-Project-State.md`
3. `02-Architecture/Database-and-Drift-Architecture.md`
4. `04-Decisions/ADR-0001-Drift-Primary-with-Sqflite-Fallback.md`
5. `04-Decisions/ADR-0002-Database-Lifecycle-Singleton.md`
6. `06-Knowledge/Database-Migration-Guide.md`
7. *Related Code*: `lib/src/data/local/`, `lib/src/data/repositories/drift/`

### 4. Security / PIN / Biometrics / Lifecycle Change
1. `00-Control/Project-Constitution.md`
2. `00-Control/Current-Project-State.md`
3. `02-Architecture/Security-and-Authentication.md`
4. `04-Decisions/ADR-0004-PIN-Biometrics-Fail-Closed-Model.md`
5. *Related Code*: `lib/src/security/`, `lib/src/screens/security/`

### 5. Backup / Export / Restore Change
1. `00-Control/Project-Constitution.md`
2. `00-Control/Current-Project-State.md`
3. `02-Architecture/Backup-and-Restore-Architecture.md`
4. `04-Decisions/ADR-0005-Safe-Merge-Transactional-Restore.md`
5. `06-Knowledge/Backup-Format-Specification.md`
6. *Related Code*: `lib/src/services/export/`

### 6. Build / Release / APK Pipeline
1. `00-Control/Project-Constitution.md`
2. `00-Control/Current-Project-State.md`
3. `03-Engineering/Build-and-Release-Pipeline.md`
4. `04-Decisions/ADR-0006-Standardized-Five-Target-APK-Pipeline.md`
5. *Related Code*: `scripts/build_apks.ps1`, `android/app/build.gradle`
