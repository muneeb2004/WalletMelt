# WalletMelt

**Know where your money went.**

WalletMelt is a local-first household expense tracker for people who reach the end of the month and wonder where their money went. It tracks rent, utilities, groceries, maintenance, custom categories, budgets, and local receipt/bill images without login, cloud storage, a backend, or a remote database.

## Tech Stack

- Flutter 3.44.2 + Dart 3.12.2
- `go_router` 17.3.0 for navigation
- `provider` 6.1.5+1 for app state
- `sqflite` 2.4.3 for local structured records
- `path_provider` 2.1.5 + app documents directory for receipt files
- `image_picker` 1.2.2 for camera/gallery capture
- `flutter_image_compress` 2.4.0 for local image optimization
- `shared_preferences` 2.5.5 for lightweight settings
- `fl_chart` 1.2.0 for charts
- `intl` 0.20.2 for currency/date-adjacent formatting
- `flutter_lints` 6.0.0 for analyzer rules
- Material 3 with a WalletMelt liquid-glass theme

## Setup

Install Flutter, then from this repository:

```bash
flutter pub get
flutter create . --platforms android,ios --project-name wallet_melt --org app.walletmelt
flutter pub get
```

The second command is only needed because this repository was scaffolded without access to the Flutter CLI in the current environment. It generates native Android/iOS runner files while preserving `lib/`, `test/`, `README.md`, and `docs/`.

## Run

Android:

```bash
flutter run -d android
```

iOS:

```bash
flutter run -d ios
```

Camera/gallery receipt capture requires the native permissions generated/configured for Android and iOS. If you regenerate native folders, add camera/photo usage descriptions to iOS `Info.plist` and Android media/camera permissions as needed.

## Verified Android State

Modernization and Android runtime QA are verified on Flutter 3.44.2 stable and Dart 3.12.2 using `D:\flutter\bin\flutter.bat`.

Environment:

- Flutter 3.44.2
- Dart 3.12.2
- Android SDK 36.1.0
- Java/JDK: `D:\AndroidStudioNew\jbr`
- Android emulator: `WalletMelt_API_36` / `emulator-5554`, Android 16 API 36
- AVD storage: `D:\AndroidAVDHome` because the default C: AVD location did not have enough free space for this image

Verified commands:

```bash
flutter --version
flutter doctor
flutter pub get
flutter pub outdated
flutter pub upgrade --major-versions
flutter analyze
flutter test
flutter devices
flutter emulators
flutter run -d emulator-5554
flutter build apk --debug
flutter build apk --release
```

Status:

- `flutter pub get`: passes.
- `flutter analyze`: passes with no issues.
- `flutter test`: passes, 5 tests.
- Debug APK: passes at `build\app\outputs\flutter-apk\app-debug.apk` (about 146.2 MB in the latest local debug build).
- Release APK: passes at `build\app\outputs\flutter-apk\app-release.apk` (about 50.6 MB).
- Android runtime: launches on `emulator-5554`.
- Direct dependencies modernized to `fl_chart` 1.2.0, `go_router` 17.3.0, `intl` 0.20.2, and `flutter_lints` 6.0.0.
- Baseline analyzer repairs included the `Category` import alias, deprecated API replacements, async context safety fixes, and a WalletMelt smoke test replacing the stale counter template test.
- Runtime fixes during Android QA wrapped decorated `ListTile` usage in transparent `Material`, made post-save navigation explicit after the app-state refresh, and added the missing read-only grocery item section to expense detail.
- Android QA covered launch, onboarding, dashboard empty and populated states, add-expense validation/save/persistence, grocery itemization/detail display, gallery cancellation, history, expense detail, soft delete, restore, insights charts, settings, and theme switching.
- Known build warning: `flutter_image_compress_common` applies the Kotlin Gradle Plugin directly. Current builds pass, but future Flutter versions may fail until the plugin migrates to Built-in Kotlin.
- Windows build stability workaround in `android/gradle.properties`: `kotlin.incremental=false`, `kotlin.compiler.execution.strategy=in-process`, and `org.gradle.parallel=false`.

## Folder Structure

```text
lib/
  main.dart
  src/
    app/
    components/
    constants/
    data/
    screens/
    services/
    state/
    theme/
    types/
    utils/
docs/
test/
```

## Local Storage

SQLite stores expenses, categories, grocery itemization, budgets, and sync metadata. Expenses use `deletedAt` for soft delete, enabling recycle-bin restore before permanent deletion.

## Receipt Storage

Receipt and bill images are saved locally in the app documents directory, not in SQLite and never remotely. Expenses store the local file URI. The receipt storage service is abstracted so cloud storage can be introduced later.

## Design System

WalletMelt uses a warm liquid-glass finance visual system: soft cream/mint backgrounds, translucent surfaces, restrained Melt Gold accents, rounded cards, floating navigation, accessible text contrast, and calm motion.

## Future Roadmap

- User login
- Cloud backup and cross-device sync
- Shared household budgets
- OCR receipt scanning
- Automatic bill reminders
- Export to CSV/PDF
- Yearly analytics
- Subscription model
- Bank/SMS integrations if appropriate

## Known Limitations

- Export is intentionally not included in v1.
- Biometric lock is intentionally not included in v1.
- Recurring reminders/local notifications are intentionally not included in v1.
- Camera capture, real photo selection, and image compression fallback were not fully exercised on the headless emulator; gallery cancellation was verified.
- Physical Android hardware, iOS runtime, and multiple device-size passes remain outside this local verification.
