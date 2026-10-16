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
- `lib/src/components/`: Reusable, dumb or semi-smart presentation components (`WMCard`, `CategoryIcon`).
- `lib/src/constants/`: App constants, standard category definitions.
- `lib/src/data/local/`: Database tables, Drift database definitions, connections.
- `lib/src/data/repositories/drift/`: Repository implementations mapping Drift classes to domain entities.
- `lib/src/providers/`: Riverpod providers for repository dependency injection.
- `lib/src/screens/`: Route-level screens and feature dialogs.
- `lib/src/security/`: PIN hashing, lock state controller, biometric interface, root detection.
- `lib/src/services/`: Platform services (receipts, export/restore, SVG customization).
- `lib/src/state/`: AppState ChangeNotifier managing UI state.
- `lib/src/theme/`: Tonal palette (`wm_palette.dart`), type scale (`wm_type.dart`), `WMCard`, spacing, motion, `ThemeData`.
- `lib/src/types/`: Domain entity models.
- `lib/src/utils/`: Currency formatters, date utilities, validators.

## 3. UI & Styling Rules
- Use `WMCard` for every card panel. `WMGlassSurface`, `FlatCard`, `LiquidGlass`, `WMDarkHeroCard` and `AppCard` are legacy wrappers; never use them in new code.
- Never hardcode colours or font sizes. Use `Theme.of(context).colorScheme`, `context.money` (status colours) and `textTheme` (six-step scale). See [[Design-System-and-UX]] and [[ADR-0010-Tonal-Material3-Design-System-and-Brand]].
- `test/theme/design_token_guard_test.dart` enforces a ratchet; do not raise its baselines.
- Category icon rendering must consume `CategoryIcon` to ensure user-defined SVG overrides reflect globally.
- Form inputs must validate non-empty and non-zero positive amounts where appropriate.
