# WalletMelt v1.0.0 — Production Release Manifest

This document represents the immutable technical release record for WalletMelt v1.0.0.

---

## 1. Technical Identity & Environment

| Field | Value |
| :--- | :--- |
| **Application** | WalletMelt |
| **Version** | `1.0.0` |
| **Build Number** | `3` |
| **Package / Application ID** | `app.walletmelt.wallet_melt` |
| **Flutter Version** | `3.44.2` (channel stable, revision `c9a6c48423`) |
| **Dart Version** | `3.12.2` (DevTools `2.57.0`) |
| **Android Compile SDK** | `36` |
| **Android Target SDK** | `35` |
| **Android Minimum SDK** | `21` |
| **Database Schema Version** | `1` (`wallet_melt.db`, Drift SQLite engine) |

---

## 2. Release Distribution Artifacts

| Distribution Format | Path | File Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **Android App Bundle (AAB)** | `build/app/outputs/bundle/release/app-release.aab` | `62.3 MB` | `4CD2825E06CE7945FD683A0041817DFDE8D100D7998B9DDF2E878FDE5911E935` |
| **Android Package (APK)** | `build/app/outputs/flutter-apk/app-release.apk` | `63.8 MB` | `FDAEC4609916F404B0FBFD8C1D789F29F2AE43408935AB1E48492B0C4AD86C41` |

---

## 3. Verification & Quality Gates

* **Static Analysis**: `flutter analyze` — **0 issues found**
* **Automated Test Suite**: `flutter test` — **269 / 269 tests passing (100%)**
* **Clean Release Reproduction**: `flutter clean && flutter pub get && flutter analyze && flutter test && flutter build apk --release && flutter build appbundle --release` — **PASS**
* **Security Sweep**: Repository clean (0 credentials, keys, or secrets tracked)
