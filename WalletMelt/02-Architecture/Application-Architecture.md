---
type: architecture
status: stable
priority: high
created: 2026-09-13
updated: 2026-09-13
domain: architecture
related:
  - "[[Database-and-Drift-Architecture]]"
  - "[[Security-and-Authentication]]"
  - "[[Analytics-and-Calculations]]"
---

# Application Architecture

## 1. High-Level Architectural Diagram

```mermaid
graph TD
    subgraph UI ["Presentation Layer (Flutter)"]
        Screens["Screens (Home, History, Planning[Budgets/Subscriptions/Essentials], Debts; Settings and Insights are top-level routes)"]
        Components["Reusable Glass Components (WMGlassSurface, CategoryIcon)"]
        AppRouter["GoRouter (StatefulShellRoute / Nav Guard)"]
    end

    subgraph State ["State Management Layer"]
        AppState["AppState (Provider - ChangeNotifier)"]
        PinLock["PinLockController (Lifecycle & Lock State)"]
    end

    subgraph Services ["Service Layer"]
        Restorer["WalletMeltJsonRestoreService"]
        ReceiptStorage["LocalReceiptStorageService"]
        SvgService["SvgCustomizationService"]
        Biometrics["BiometricService / PinService"]
    end

    subgraph Repositories ["Repository Boundary"]
        RiverpodDI["Riverpod Providers (DI Container)"]
        DriftRepos["Drift Repositories (Expense, Budget, Debt, etc.)"]
        SqfliteFallback["Sqflite Fallback Repositories"]
    end

    subgraph Data ["Local Persistence Engine"]
        DriftDB["WalletMeltDatabase (Singleton, v9)"]
        SqfliteDB["AppDatabase (wallet_melt.db)"]
        SecureStorage["FlutterSecureStorage (PIN Salt/Hash)"]
        DiskFiles["Local Filesystem (Receipts, Custom SVGs)"]
    end

    Screens --> AppState
    Screens --> PinLock
    AppState --> DriftRepos
    AppState --> SqfliteFallback
    AppState --> Services
    RiverpodDI --> DriftRepos
    DriftRepos --> DriftDB
    SqfliteFallback --> SqfliteDB
    Services --> DriftDB
    Services --> SecureStorage
    Services --> DiskFiles
```

## 2. Layer Responsibilities

1. **Presentation Layer (`lib/src/screens/`, `lib/src/components/`)**:
   - Strictly declarative UI widgets.
   - Watches `AppState` via `context.watch<AppState>()` or `Consumer`.
   - Never accesses database queries or sqlite connection handles directly.
2. **State Management (`lib/src/state/app_state.dart`)**:
   - Central application coordinator.
   - Dispatches mutations to Drift repositories, synchronizes fallback layers, and notifies listeners.
3. **Repository Layer (`lib/src/data/repositories/drift/`)**:
   - Implements domain repository contracts.
   - Maps raw database data classes to typed immutable domain objects.
4. **Local Persistence Engine (`lib/src/data/local/`)**:
   - `WalletMeltDatabase`: Drift SQLite engine managing connection pooling, schemas, foreign keys, and transactions.
   - `AppDatabase`: Legacy sqflite fallback.
