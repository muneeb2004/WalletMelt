# WalletMelt Architecture

WalletMelt is a local-first Flutter app. The v1 product has no login, backend, cloud database, or remote receipt storage. The architecture is still shaped for future accounts, cloud sync, household sharing, backup/restore, and cross-device access.

## Product Scope

V1 includes onboarding, selectable currency, dark mode, default and custom categories, expenses, grocery itemization, local receipt capture from camera/gallery, category budgets, dashboard insights, history search/filter/sort, expense detail/editing, and soft delete through a recycle-bin flow.

Not included in v1: login, cloud backup, cross-device sync, shared households, export, OCR, recurring reminders, bank/SMS integrations, and biometrics.

## Layers

- `screens/`: route-level UI for onboarding, dashboard, add/edit expense, history, insights, and settings.
- `components/`: reusable glass surfaces, charts, navigation, category chips, and expense list rows.
- `state/`: app-level coordinator that loads repositories/services and exposes simple async actions.
- `data/`: SQLite database, schema, and repositories.
- `services/`: platform-facing services for receipt storage and settings.
- `types/`: typed domain entities.
- `utils/`: validation, currency formatting, dates, and derived insight selectors.

## Modernized Runtime Stack

The current verified toolchain is Flutter 3.44.2 stable with Dart 3.12.2, Android SDK 36.1.0, and Java from `D:\AndroidStudioNew\jbr`. Android runtime QA used the `WalletMelt_API_36` emulator on `emulator-5554` with Android 16 API 36.

Resolved direct package versions include:

- `go_router` 17.3.0
- `fl_chart` 1.2.0
- `intl` 0.20.2
- `provider` 6.1.5+1
- `sqflite` 2.4.3
- `path_provider` 2.1.5
- `image_picker` 1.2.2
- `flutter_image_compress` 2.4.0
- `shared_preferences` 2.5.5
- `flutter_lints` 6.0.0

The migration did not change v1 product scope. Navigation still uses the same `StatefulShellRoute.indexedStack` tab model, app state remains `provider`-backed, and local SQLite/file storage remains the source of truth. Analyzer migration changes were limited to import disambiguation, deprecated Flutter API replacements, async `BuildContext` safety, const cleanups, and replacing the stale generated counter widget test with a WalletMelt boot smoke test. Runtime migration fixes wrapped decorated `ListTile` usage in transparent `Material`, made add/edit save navigation explicit after app-state refresh, and rendered saved grocery itemization on expense detail.

Verified commands for this state: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, `flutter build apk --release`, and `flutter run -d emulator-5554`. Analyzer passes with no issues, tests pass with 5 tests, the debug APK builds at `build\app\outputs\flutter-apk\app-debug.apk`, and the release APK builds at `build\app\outputs\flutter-apk\app-release.apk` at about 50.6 MB.

The Android build keeps this Windows Gradle workaround in `android/gradle.properties` because Kotlin incremental/parallel compilation previously failed across the project drive and Pub cache paths:

```properties
kotlin.incremental=false
kotlin.compiler.execution.strategy=in-process
org.gradle.parallel=false
```

Current APK builds also warn that `flutter_image_compress_common` applies the Kotlin Gradle Plugin directly. This is not a current blocker, but it is a future Flutter compatibility risk until that plugin supports Built-in Kotlin.

Android runtime QA covered launch, onboarding, dashboard, add expense, validation, saved-expense persistence, grocery itemization, grocery detail display, gallery cancellation, history, expense detail, soft delete, restore, insights charts, settings, and theme switching. Camera capture, real gallery image attachment, physical-device behavior, iOS runtime, and broad device-size QA remain separate verification tasks.

## Local Persistence

Structured records use SQLite through `sqflite`. The schema includes:

- `categories`
- `expenses`
- `grocery_items`
- `category_budgets`
- `sync_metadata`

`sync_metadata` is intentionally present in v1 so future cloud sync can attach remote IDs, local versions, timestamps, and sync states without changing UI contracts.

## Receipt Storage

Receipt images are stored in the app documents directory under `receipts/`. The expense table stores only the local file URI. Images are compressed before persistence when the native compressor succeeds. Missing or corrupt files are handled by UI error builders instead of crashing.

## Future Sync Path

Repositories are the persistence boundary. A future sync implementation should add:

- remote IDs and sync states through `sync_metadata`
- conflict resolution in repository/service layer
- authenticated account context above repositories
- background backup/restore jobs
- upload adapter behind `ReceiptStorageService`

The UI should continue calling state/repository actions rather than talking directly to SQLite or remote APIs.

## Motion System

The current v1 uses native Flutter implicit animations, Hero receipt previews, modal bottom sheets, animated category chips, Material transitions, and chart entry rendering. If the motion system grows, centralize durations/curves in `theme/` and prefer `AnimationController` only where implicit animation is insufficient.
