---
name: flutter_skill
description: Guidelines for safe Flutter widget structure, styling tokens, spacing conventions, layout constraints, and visual presentation layer modifications.
---

# WalletMelt Flutter Skill

## Widget Structure Conventions
- **Feature Isolation:** Keep screens under [lib/src/screens/](file:///D:/Web%20Projects/WalletMelt/lib/src/screens) and reusable elements under [lib/src/components/](file:///D:/Web%20Projects/WalletMelt/lib/src/components).
- **Separation of Concerns:** Separate the view-only widgets from state controllers. Widgets should consume data and trigger callback events, avoiding direct database operations.
- **Component Granularity:** Break large screens into smaller widget classes (e.g., `ExpenseCard`, `BudgetProgressBar`) inside a `components/` subfolder under each screen feature folder.

## Safe Refactor Rules
- **No Signature Breaking:** Avoid altering existing constructor parameters of core screen widgets unless updating all routing contexts.
- **Immutable Arguments:** Mark arguments as `final` and widgets as `@immutable`. Always supply `super.key` to constructors.
- **State Preservation:** When refactoring stateful widgets, confirm that inputs in `TextEditingController` or scroll positions are not lost.
- **Scope Limit:** Do not make any database, repository, provider, or state changes during visual/UI polish tasks.

## Theme & Token Usage
- **Material 3 Alignment:** Ensure all visual elements align with the light/dark definitions in [wallet_melt_theme.dart](file:///D:/Web%20Projects/WalletMelt/lib/src/theme/wallet_melt_theme.dart).
- **No Hex-Code hardcoding:** Never hardcode colors via `Color(0xFF...)`. Instead, use context tokens:
  - `Theme.of(context).colorScheme.primary`
  - `Theme.of(context).colorScheme.surfaceContainer` (or surface variant)
  - `Theme.of(context).colorScheme.error`
- **Spacing Guidelines:** Use a base spacing scale (4, 8, 12, 16, 24, 32) wrapped in `SizedBox` or `Padding` to maintain design grid coherence.

## Responsive Layout Checks
- **Overflow Prevention:** Always wrap scrollable components (like expense itemization lists) in `ListView`, `SingleChildScrollView`, or `CustomScrollView`.
- **Adaptability:** Utilize `LayoutBuilder` or `MediaQuery` values to scale padding, grid dimensions, and alignments on larger screens or portrait/landscape shifts.

## Common Flutter CLI Commands
- Fetch dependencies:
  ```powershell
  flutter pub get
  ```
- Run static analysis:
  ```powershell
  flutter analyze
  ```
- Run unit and widget tests:
  ```powershell
  flutter test
  ```
- Run code generation:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  ```
- Build target debug Android binary:
  ```powershell
  flutter build apk --debug
  ```
