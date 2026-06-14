# WalletMelt Agent Routing Guide

This document defines how specialized Antigravity sub-agents cooperate, which agents to invoke for specific tasks, and the rules governing conflict avoidance.

---

## 1. Agent Responsibilities & Task Mapping

When tackling a new issue, feature, or refactor in the WalletMelt repository, use the following mapping to identify the appropriate specialized sub-agents:

| Task Type | Assigned Specialist Agent | Secondary / Reviewer Agent | Associated Skills |
| :--- | :--- | :--- | :--- |
| **Architecture / State Migration** | [Drift/Riverpod Migration Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/drift_riverpod_migration_agent/agent.json) | [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.agents/agents/flutter_architecture_guardian/agent.json) | Drift Skill, Riverpod Skill, sqflite Legacy Skill, Provider/AppState Legacy Skill, Dart Skill, Testing Skill |
| **Direct Riverpod Migration** | [Drift/Riverpod Migration Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/drift_riverpod_migration_agent/agent.json) | [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/qa_regression_agent/agent.json) | Riverpod Skill, Drift Skill, Testing Skill |
| **Expense Read Migration** | [Drift/Riverpod Migration Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/drift_riverpod_migration_agent/agent.json) | [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.agents/agents/flutter_architecture_guardian/agent.json) | Drift Skill, Provider/AppState Legacy Skill, Testing Skill |
| **Expense Write Migration** | **BLOCKED** | None | BLOCK unless explicitly approved after Android runtime QA and expense read migration are stable. |
| **UI/UX Visual Polish** | [Flutter UI/UX Polish Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/flutter_ui_ux_polish_agent/agent.json) | [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.agents/agents/flutter_architecture_guardian/agent.json) | Flutter Skill, Dart Skill, Testing Skill |
| **Test Suites / App Builds** | [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/qa_regression_agent/agent.json) | None | Testing Skill |
| **Runtime QA** | [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/qa_regression_agent/agent.json) | None | Android Runtime QA Skill, Testing Skill |
| **Item Spending Intelligence** | [Product Intelligence Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/product_intelligence_agent/agent.json) | [Drift/Riverpod Migration Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/drift_riverpod_migration_agent/agent.json) | Product Analytics Skill, Drift Skill, Dart Skill, Testing Skill |
| **Data Exports / Backups** | [Export/Backup Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/export_backup_agent/agent.json) | [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/qa_regression_agent/agent.json) | Export/Backup Skill, Drift Skill, sqflite Legacy Skill, Testing Skill |

---

## 2. Dynamic Workflows & Agent Cooperation

### Workflow A: Migrating State or Database Layers
1. **Initiate:** Invoke the [Drift/Riverpod Migration Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/drift_riverpod_migration_agent/agent.json) to draft Drift database tables, update repository code, or define Riverpod providers.
2. **Verify Code:** Invoke the [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/qa_regression_agent/agent.json) to run `flutter analyze` and `flutter test`.
3. **Review Integrity:** Invoke the [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.agents/agents/flutter_architecture_guardian/agent.json) to review the code changes, ensuring that fallback read strategies are present and legacy Provider models remain functional.

### Workflow B: UI/UX Visual Polish
1. **Initiate:** Invoke the [Flutter UI/UX Polish Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/flutter_ui_ux_polish_agent/agent.json) to improve layout spacing, spacing density, cards, font styling, or glassmorphic elements.
2. **Review Integrity:** Invoke the [Flutter Architecture Guardian](file:///D:/Web%20Projects/WalletMelt/.agents/agents/flutter_architecture_guardian/agent.json) to confirm that no presentation edits break state-management controllers or touch database APIs.
3. **Verify App:** Invoke the [QA and Regression Agent](file:///D:/Web%20Projects/WalletMelt/.agents/agents/qa_regression_agent/agent.json) to execute static analysis and check widget tests.

---

## 3. Strict Conflict & Scope Rules

- **Codex Active Lock:** If Codex is actively modifying the project, **do not edit app source files** or database files.
- **Sequential Migration over UI Polish:** If a database/state migration phase is active, all UI/UX polish tasks must wait.
- **Strict Visual Scope:** During a UI/UX polish phase, database definitions (`wallet_melt_database.dart`), repositories (`drift_*_repository.dart`), providers (`*_providers.dart`), and test scripts are **strictly off-limits** for the polish agent.
- **Generated-File Boundaries:** Never edit `.g.dart` files directly. If database schema tables require updates, edit the source file [wallet_melt_database.dart](file:///D:/Web%20Projects/WalletMelt/lib/src/data/local/wallet_melt_database.dart) and run the code generator:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Justify Database Schema Upgrades:** Do not introduce new tables, alter constraints, or drop fields without documenting and justifying the change. All schema edits require approval from the Architecture Guardian.
- **Honest QA Reporting:** If Android runtime smoke testing has not been run or is in progress, the QA status must be reported as **PENDING** or **PENDING RUNTIME QA**. Never mark a task as "PASS" unless it has been verified in a running emulator or target device.
