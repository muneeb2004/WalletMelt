# WalletMelt — Release Candidate Baseline

**Application**: WalletMelt  
**Release Candidate Version**: `1.0.0+3`  
**Release Status**: **READY FOR RELEASE**  
**Date**: August 22, 2026  

---

## 1. Environment & Build Baseline

| Metric | Value |
| :--- | :--- |
| **Git Commit Hash** | `903a964` |
| **Flutter Version** | `3.44.2` (channel stable) |
| **Dart Version** | `3.12.2` (DevTools 2.57.0) |
| **Android Compile SDK** | `36` (Android 16 / Vanilla Ice Cream) |
| **Android Target SDK** | `35` (Android 15) |
| **Android Min SDK** | `21` (Android 5.0 Lollipop) |
| **Java / JVM Version** | `Java 17` |
| **Application Package ID**| `app.walletmelt.wallet_melt` |
| **Database Engine** | Drift SQLite (`drift: ^2.34.0`) |
| **Database Schema Version**| `1` (`wallet_melt.db`) |
| **Release Artifact** | `build/app/outputs/flutter-apk/app-release.apk` |
| **Release APK Size** | `63.8 MB` |

---

## 2. Quality & Validation Metrics

| Suite | Status | Details |
| :--- | :---: | :--- |
| **Static Analysis** | **PASS** | `flutter analyze` — 0 issues found |
| **Automated Tests** | **PASS** | `flutter test` — 269 / 269 tests passing |
| **Clean Release Build** | **PASS** | `flutter build apk --release` — Exit code 0 |
| **Screen Protection** | **PASS** | `FLAG_SECURE` window security enabled on native Android |
| **Security Storage** | **PASS** | `FlutterSecureStorage` with fail-closed error recovery |
| **Biometric Auth** | **PASS** | `local_auth` platform-adaptive with in-flight concurrency lock |

---

## 3. Production Functional Subsystems Verified

1. **Financial Core & Calculations**:
   - Budget remaining calculations (`Remaining = Budget - Actual Spending`).
   - Sales tax calculations (`Total = Subtotal + Tax Amount`).
   - Fuel expense calculations (`Litres × Price/L`).
   - Grocery itemization calculations (`∑(Quantity × Unit Price)`).
   - Debt balances & repayments (`Net Position = Receivables - Liabilities`).
   - Soft-delete and restore cycles across all database entities.

2. **Security & Authentication**:
   - PIN creation, verification, change, and disablement.
   - Device-adaptive biometric unlock (Face ID, Touch ID, Fingerprint).
   - 5-attempt threshold with 30-second lockout cooldown.
   - Deterministic 30-second background grace period.
   - Screen switcher privacy (`FLAG_SECURE`).

3. **Data Management & Backup / Restore**:
   - Local-first persistence via Drift SQLite.
   - JSON export and safety backup packaging.
   - Checksum-validated restore with dry-run conflict resolution.
   - Atomic rollback on I/O or relation validation failures.

4. **UI & Accessibility**:
   - Responsive layout verified on 320px, 360px, 375px, 390px, and 430px viewports.
   - WCAG-compliant high-contrast dark and light theme tokens.
   - Screen reader semantic accessibility for number pad and PIN indicators.
