---
name: riverpod_skill
description: Rules for using Riverpod providers, handling AsyncValue, invalidating state, and managing coexistence with legacy AppState during the transition.
---

# WalletMelt Riverpod Skill

## ProviderScope Location
- **Bootstrapping Scope:** The global `ProviderScope` must remain at the very root of the widget tree inside `WalletMeltBootstrap` in [wallet_melt_app.dart](file:///D:/Web%20Projects/WalletMelt/lib/src/app/wallet_melt_app.dart).
- **Testing Scope:** During testing, wrap the harness inside a `ProviderScope` and override database/repository providers with mock implementations.

## Provider Naming Conventions
- **Read Providers:** Name read-only data streams using the `Provider` or `FutureProvider` suffixes (e.g., `categoriesProvider`, `budgetByCategoryProvider`).
- **Repository Providers:** Database and repository handles should end with `RepositoryProvider` (e.g., `driftCategoryRepositoryProvider`, `driftExpenseRepositoryProvider`).
- **Naming format:** Use camelCase matching the resource they expose.

## AsyncValue Handling
- **UI Safety:** When consuming a `FutureProvider` or `StreamProvider` in a widget, always use `asyncValue.when(...)` to render loading, error, and data states explicitly.
- **Graceful Fallbacks:** Provide visual loaders or retain cached values during invalidation cycles to prevent screen flickering.

## Invalidation Rules
- **Refresh State:** Trigger refetches of Riverpod providers using `ref.invalidate(provider)` or `ref.refresh(provider)` from controllers when data updates are written.
- **Maintain Sync:** Let providers react naturally to underlying streams if the database library supports reactive streams (like Drift's select streams).

## Coexistence & Migration Strategy
- **AppState Priority:** AppState remains the primary screen-facing state management layer. Do not migrate entire screens to Riverpod without explicit approval.
- **Narrow Consumers:** Direct Riverpod reads inside widgets must be narrow and low-risk (e.g., reading metadata or static configurations).
- **No Unapproved Generators:** Do not introduce code generation for Riverpod unless it is already adopted in the project.
- **Fallback Preservation:** Ensure sqflite repository fallback behavior remains supported under the new providers.
