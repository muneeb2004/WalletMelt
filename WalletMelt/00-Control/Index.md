---
type: index
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-17
domain: control
related: []
---

# WalletMelt Engineering Control Plane

Welcome to the **WalletMelt Engineering Control Plane**. This Obsidian vault serves as the persistent memory, architectural boundary, and governance layer for WalletMelt.

> **Critical Operating Principle**:
> The codebase is the source of truth for implemented behavior. This vault is the source of truth for project intent, requirements, architecture, engineering constraints, technical decisions, and AI agent operating rules. When they disagree, resolve the conflict explicitly and update the appropriate authority.

---

## 🧭 Fast Navigation Index

### 1. Control & Governance
- [[Project-Constitution]]: Highest-level project boundaries, invariants, and quality expectations.
- [[AI-Engineering-Protocol]]: Standard operating protocol, drift check, and session discipline for AI agents.
- [[Current-Project-State]]: Real-time verified release status, architecture summary, and active limits.
- [[Context-Loading-Guide]]: Minimal-sufficient context loading chains for common task domains.

### 2. Product & UX
- [[Product-Requirements]]: Core functional requirements, scope definitions, and out-of-scope boundaries.
- [[Design-System-and-UX]]: Brand and Tonal Material 3 design system: colour roles, type scale, components, voice, and rules for future work.

- [[Student-Market-Strategy]]: *(proposed)* Pakistan-first, then international student finance strategy.
- [[Gap-Analysis-vs-Code]]: Verified gaps between the strategy and the current code.

### 3. Architecture & Subsystems
- [[Application-Architecture]]: Layered architecture, presentation boundaries, and service interactions.
- [[Database-and-Drift-Architecture]]: Drift schema v9, 22 managed tables, and singleton lifecycle rules.
- [[Security-and-Authentication]]: PIN salt hashing, biometric verification, 30s grace window, and fail-closed state.
- [[Analytics-and-Calculations]]: Deterministic formulas for Days Remaining (+1 logic), Daily Allowance, Pace, and Debt.
- [[Backup-and-Restore-Architecture]]: Safe-merge transactional restore pipeline and conflict detection.

### 4. Engineering Conventions & Pipelines
- [[Flutter-Conventions]]: Dart sound null safety, model immutability, directory taxonomy, and styling tokens.
- [[Build-and-Release-Pipeline]]: Standardized 5-target APK build script (`.\scripts\build_apks.ps1`) and versioning.
- [[Testing-Conventions]]: Testing standards, widget test async I/O rules, and in-memory Drift isolation.

### 5. Architectural Decision Records (ADRs)
- [[ADR-0001-Drift-Primary-with-Sqflite-Fallback]]: Primary Drift adoption with legacy fallback safety.
- [[ADR-0002-Database-Lifecycle-Singleton]]: Single-instance connection cache eliminating double-open locks.
- [[ADR-0003-Provider-UI-with-Riverpod-DI]]: Coexistence model: Provider for UI state, Riverpod for repository DI.
- [[ADR-0004-PIN-Biometrics-Fail-Closed-Model]]: Fail-closed local security, 30s grace, and 5-attempt lockout.
- [[ADR-0005-Safe-Merge-Transactional-Restore]]: Additive safe-merge JSON restore under a single transaction.
- [[ADR-0006-Standardized-Five-Target-APK-Pipeline]]: Unified compilation of all 5 production and screenshot APKs.
- [[ADR-0007-SVG-Customization-and-Global-Overrides]]: Disk-persisted SVG overrides with global real-time reflection.
- [[ADR-0008-Deterministic-Financial-Metrics-Engine]]: Pure mathematical engine and explicit transparency menu.
- [[ADR-0009-Complete-Backup-v2-and-Safe-Full-Replace]]: Complete checksummed backup v2 and safe, verified Full Replace.
- [[ADR-0010-Tonal-Material3-Design-System-and-Brand]]: Tonal Material 3 system, single indigo brand, one card, one type scale, token guard.
- [[ADR-0011-Accounts-Derived-Balance-and-Transfers]]: (accepted) accounts, derived balance, transfers and reconcile; see [[Balance-Income-and-Auto-Capture-Exploration]].

### 6. Work & Knowledge
- [[Work-Tracker]]: Current status (Now, Next, Later, Blocked).
- [[Technical-Debt-Registry]]: Controlled technical debt registry (no unauthorized refactors).
- [[Database-Migration-Guide]]: Step-by-step schema upgrade and migration rules.
- [[Backup-Format-Specification]]: JSON backup schema and conflict resolution specs.
- [[Toolchain-and-Environment]]: Verified SDKs, environment variables, and essential commands.

---

## 📚 Relationship to `docs/` (repo root)
The `docs/*.md` files are **historical phase plans and specs**, not the live authority. Where they overlap, this vault wins:
| `docs/` file | Live vault note |
|---|---|
| ARCHITECTURE.md | [[Application-Architecture]], [[Database-and-Drift-Architecture]] |
| PRODUCT_THINKING.md | [[Product-Requirements]], [[Student-Market-Strategy]] |
| WALLETMELT_JSON_BACKUP_FORMAT_SPEC.md | [[Backup-Format-Specification]] (note: spec is ahead of code) |
| WALLETMELT_RESTORE_* (readiness, QA matrix, transaction design) | [[Backup-and-Restore-Architecture]], [[ADR-0005-Safe-Merge-Transactional-Restore]] |
| WALLETMELT_PHASE_9B / 12B plans, V2_MIGRATION_STATUS | [[Database-Migration-Guide]], [[Current-Project-State]] |
| WALLETMELT_RELEASE_READINESS.md | [[Build-and-Release-Pipeline]] |
| WALLETMELT_V3_ROADMAP.md (cloud platform; conflicts with offline-first Constitution) | [[Work-Tracker]] (Later); needs an ADR before any work |
