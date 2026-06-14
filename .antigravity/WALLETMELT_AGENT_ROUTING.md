# WalletMelt Agent Routing Guide

This document defines how specialized Antigravity sub-agents cooperate, which agents to invoke for specific tasks, and the strict rules governing conflict avoidance.

---

## 1. Agent Responsibilities & Task Mapping

When tackling a new issue, feature, or refactor in the WalletMelt repository, use the following mapping to identify the appropriate specialized sub-agents:

| Task Type | Assigned Specialist Agent | Secondary / Reviewer Agent |
| :--- | :--- | :--- |
| **Architecture / State Migration** | [Drift/Riverpod Migration Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/drift_riverpod_migration_agent.md) | [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/flutter_architecture_guardian.md) |
| **UI/UX Visual Polish** | [Flutter UI/UX Polish Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/flutter_ui_ux_polish_agent.md) | [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/flutter_architecture_guardian.md) |
| **Test Suites / App Builds** | [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/qa_regression_agent.md) | None |
| **Item Spending Intelligence** | [Product Intelligence Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/product_intelligence_agent.md) | [Drift/Riverpod Migration Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/drift_riverpod_migration_agent.md) |
| **Data Exports / Backups** | [Export/Backup Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/export_backup_agent.md) | [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/qa_regression_agent.md) |
| **Runtime Smoke Testing** | [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/qa_regression_agent.md) | None |

---

## 2. Dynamic Workflows & Agent Cooperation

### Workflow A: Migrating State or Database Layers
1. **Initiate:** Invoke the [Drift/Riverpod Migration Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/drift_riverpod_migration_agent.md) to draft Drift database tables, update repository code, or define Riverpod providers.
2. **Verify Code:** Invoke the [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/qa_regression_agent.md) to run `flutter analyze` and `flutter test`.
3. **Review Integrity:** Invoke the [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/flutter_architecture_guardian.md) to review the code changes, ensuring that fallback read strategies are present and legacy Provider models remain functional.

### Workflow B: UI/UX Visual Polish
1. **Initiate:** Invoke the [Flutter UI/UX Polish Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/flutter_ui_ux_polish_agent.md) to improve layout spacing, spacing density, cards, font styling, or glassmorphic elements.
2. **Review Integrity:** Invoke the [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/flutter_architecture_guardian.md) to confirm that no presentation edits break state-management controllers or touch underlying database APIs.
3. **Verify App:** Invoke the [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.antigravity/agents/qa_regression_agent.md) to execute static analysis and check widget tests.

---

## 3. Strict Conflict & Scope Rules

To prevent code corruption, build failures, and collisions during collaborative development, all agents must adhere to these rules:

- **Codex Active Lock:** If Codex is actively modifying the project, **do not edit app source files** or generated database schemas. Keep all work restricted to inspecting files and creating configuration or specialist documents.
- **Sequential Migration over UI Polish:** If a database/state migration phase is active, all UI/UX polish tasks must wait. Database structures and provider states must stabilize before polishing visuals.
- **Strict Visual Scope:** During a UI/UX polish phase, database definitions (`wallet_melt_database.dart`), repositories (`drift_*_repository.dart`), providers (`*_providers.dart`), and test scripts are **strictly off-limits** for the polish agent.
- **Generated-File Boundaries:** Never edit `.g.dart` files directly. If database schema tables require updates, edit the source file [wallet_melt_database.dart](file:///D:/Web%20Projects/WalletMelt/lib/src/data/local/wallet_melt_database.dart) and run the code generator:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Justify Database Schema Upgrades:** Do not introduce new tables, alter constraints, or drop fields without documenting and justifying the change. All schema edits require approval from the Architecture Guardian.
- **Honest QA Reporting:** If Android runtime smoke testing has not been run or is in progress, the QA status must be reported as **PENDING** or **PENDING RUNTIME QA**. Never mark a task as "PASS" unless it has been verified in a running emulator or target device.
