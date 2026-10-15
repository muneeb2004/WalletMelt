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

# Flutter and Dart Conventions

## 1. Language & Typing Standards
- **Null Safety**: Strict sound null safety throughout. Never use bang operators (`!`) unless protected by a preceding null check or assertion.
- **Model Immutability**: All domain models (`lib/src/types/`) must be immutable with `final` fields and provide explicit `copyWith()` constructors.
- **Const Constructors**: Prefer `const` constructors everywhere possible to reduce unnecessary widget rebuild cycles.

## 2. Directory Taxonomy
- `lib/src/analytics/`: Mathematical financial calculation engines and snapshot models.
- `lib/src/app/`: Application bootstrap, root widgets, and router setup.
- `lib/src/components/`: Reusable, dumb or semi-smart presentation components (`WMGlassSurface`, `CategoryIcon`).
- `lib/src/constants/`: App constants, standard category definitions.
- `lib/src/data/local/`: Database tables, Drift database definitions, connections.
- `lib/src/data/repositories/drift/`: Repository implementations mapping Drift classes to domain entities.
- `lib/src/providers/`: Riverpod providers for repository dependency injection.
- `lib/src/screens/`: Route-level screens and feature dialogs.
- `lib/src/security/`: PIN hashing, lock state controller, biometric interface, root detection.
- `lib/src/services/`: Platform services (receipts, export/restore, SVG customization).
- `lib/src/state/`: AppState ChangeNotifier managing UI state.
- `lib/src/theme/`: Colors, typography, glass styling tokens.
- `lib/src/types/`: Domain entity models.
- `lib/src/utils/`: Currency formatters, date utilities, validators.

## 3. UI & Styling Rules
- Always use `WMGlassSurface.tier1()`, `tier2()`, or `tier3()` for card panels.
- Do not hardcode arbitrary hex colors; consume `WalletMeltColors`.
- Category icon rendering must consume `CategoryIcon` to ensure user-defined SVG overrides reflect globally.
- Form inputs must validate non-empty and non-zero positive amounts where appropriate.
