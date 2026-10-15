---
type: adr
status: accepted
created: 2026-08-15
updated: 2026-09-13
domain: architecture
related:
  - "[[Application-Architecture]]"
---

# ADR-0003: Provider-Coordinated UI with Riverpod Repository DI

## Status
Accepted

## Context
WalletMelt's screens were built with Flutter `Provider` (`AppState`). While Riverpod was selected to inject modern Drift repositories, migrating every screen and widget to `ConsumerWidget` or `ConsumerStatefulWidget` would cause massive churn and potential UI regressions.

## Decision
Maintain a strict coexistence architecture:
- Screen-level presentation logic continues to consume `Provider` / `AppState`.
- Riverpod is used at the root (`ProviderScope`) strictly as a dependency injection container providing Drift repository instances to `AppState`.
- Do NOT rewrite UI screens to Riverpod.

## Alternatives Considered
1. **Full Riverpod UI Rewrite**: Rejected because it would introduce high regression risk with zero user-facing benefit.
2. **Pure Service Locator (get_it)**: Rejected as Riverpod was already established for repository lifecycle scoping.

## Consequences
- **Positive**: UI screens remain stable, testable, and untouched. Repositories benefit from clean compile-time DI.
- **Negative**: Two state packages present in `pubspec.yaml` (Provider and Flutter Riverpod).

## Related Code
- `lib/src/app/wallet_melt_app.dart`
- `lib/src/state/app_state.dart`
- `lib/src/providers/`
