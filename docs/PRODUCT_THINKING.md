# WalletMelt Product Thinking

## Confirmed Requirements

- Flutter native mobile app for Android and iOS.
- User-selectable and updatable currency.
- Expense tracking only in v1; no recurring reminders or local notifications.
- Camera and gallery receipt capture.
- Grocery can be tracked as a single total and with optional itemized purchases.
- Custom categories are supported.
- No JSON/CSV export in v1.
- Dark mode is included.
- No biometric/app lock in v1.
- Basic onboarding is included.
- Category budgets are included.
- Soft delete/recycle-bin behavior is included.

## Product Agent

V1 focuses on answering one emotional question: where did my money melt this month? The core journeys are first launch, add household expense, attach receipt, review dashboard, search history, inspect insights, set budgets, and recover deleted expenses. Future roadmap includes accounts, sync, households, OCR, reminders, export, and yearly analytics.

## UX Agent

Information architecture is a four-tab shell: Dashboard, History, Insights, Settings. Add Expense is a focused full-screen flow with a large amount field, category chips, date, notes, receipt capture, and grocery itemization when Grocery is selected. Empty states must teach the next action without becoming marketing copy.

## Design System Agent

WalletMelt uses warm liquid glass: cream/mint background, translucent white or smoky dark panels, restrained Melt Gold emphasis, category color chips, soft shadows, large readable totals, and uncluttered chart cards. Glass is reserved for cards, navigation, sheets, chips, previews, and insight surfaces.

## Mobile Architecture Agent

Flutter is appropriate because the user explicitly selected it and it gives one maintainable native-feeling codebase for Android/iOS. The architecture separates UI, screens, state, repositories, services, domain types, validation, selectors, and theme. Platform integrations are behind services.

## Data Agent

SQLite is the source of truth for structured data. Receipt images live in local files and are linked by URI. `sync_metadata` prepares for future cloud sync without adding a fake backend. Expenses use `deletedAt` for soft delete and restore.

## Motion Agent

Motion is practical and native: route transitions, modal bottom sheets, Hero receipt preview, animated chips, animated glass cards, chart rendering, and button press feedback. Heavy decorative animation is excluded from v1.

## QA Agent

Primary checks cover validation, monthly totals, category totals, filtering/sorting, settings persistence, soft delete/restore/permanent delete, receipt attach/remove, missing receipt files, empty first launch, currency formatting, date handling, and migration behavior.

## Modernization QA Notes

The package modernization preserves the v1 scope: no login, cloud sync, backend, export, OCR, recurring reminders, or biometrics were added. Verified automated checks after upgrading to Flutter 3.44.2 / Dart 3.12.2 and the latest compatible direct package stack:

- `flutter pub get`: passes.
- `flutter analyze`: passes with no issues.
- `flutter test`: passes, 5 tests.
- `flutter build apk --debug`: passes.
- `flutter build apk --release`: passes at about 50.6 MB.
- `flutter run -d emulator-5554`: launches on Android.

Android runtime QA used the `WalletMelt_API_36` emulator on Android 16 API 36. The verified flows were first launch, onboarding with WalletMelt identity and the "Know where your money went." slogan, currency selection, dashboard empty and populated states, add-expense validation and save, grocery itemization and detail display, saved-data persistence after restart, gallery picker cancellation, history list/filter/sort surface, expense detail, soft delete, restore from recycle-bin state, insights charts, settings, and theme switching.

Three runtime-only issues were fixed during QA: decorated `ListTile` widgets now have a transparent `Material` ancestor, save navigation now explicitly returns to the correct route after app-state refresh, and grocery expense detail now renders saved itemized grocery lines. The Android build keeps the Kotlin incremental workaround in `android/gradle.properties`, and `flutter_image_compress_common` still emits a future Kotlin Gradle Plugin compatibility warning.

Remaining QA limitations: camera capture, real gallery image selection, compression failure fallback, physical Android hardware, iOS runtime, and multiple emulator size classes were not fully exercised in this pass.
