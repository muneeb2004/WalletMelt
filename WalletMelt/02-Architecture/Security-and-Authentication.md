---
type: architecture
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-15
domain: architecture
related:
  - "[[Application-Architecture]]"
  - "[[ADR-0004-PIN-Biometrics-Fail-Closed-Model]]"
---

# Security and Authentication

## 1. Threat Model & Privacy Stance
- WalletMelt stores sensitive personal financial records locally. The threat model protects against local physical access (lost/borrowed devices) and background observation.
- No remote credential verification exists.

## 2. Authentication Architecture
- **Master PIN**: 4-digit code derived with **PBKDF2-HMAC-SHA256** (100,000 iterations, 32-byte output; `pin_hash.dart`) using a random 32-byte per-device salt (`Random.secure()`), both stored in `FlutterSecureStorage`. Iterations drop to 100 on web/`FLUTTER_TEST`. *(Corrected 2026-10-15: earlier note said deterministic SHA-256.)*
- **Biometric Authentication**: Local biometric evaluation via `local_auth`. Enabled only when the device reports support (`canCheckBiometrics || isDeviceSupported()`), biometrics are enrolled, and the user has an active PIN configured as fallback.
- **Fail-Closed Principle**: If secure storage reads fail, device hardware state cannot be queried, or exceptions occur, `PinLockController` immediately forces `isLocked = true`.

## 3. Session Lifecycle & Invariants
1. **Background Grace Period**: Fixed 30-second window. If app transitions to `paused` / `hidden` and returns within 30 seconds, session remains unlocked. If $\ge 30$ seconds elapse, session locks immediately.
2. **Lockout Throttling**: 5 consecutive incorrect PIN attempts enforce a strict 30-second lockout timer persisted in secure storage.
3. **Screen Protection (`FLAG_SECURE`)**: Native window flag enabled on startup via `SecurityUtils.enableSecureScreen()`, obscuring app previews in OS recent-app switchers.

## 4. Verified Code Facts (2026-10-15)
- Lockout (5 fails / 30 s, persisted) is enforced in the **UI** (`pin_lock_screen.dart`), not in `PinService.verifyPin`.
- `FLAG_SECURE` is set in `MainActivity.kt` and via `security_utils.dart`; skipped only in debug screenshot mode.
- Present but **unreferenced** in `lib/`: `LedgerIntegrityService` (hard-coded software fallback key), `SecureClipboardService`; `RootDetectionService` is advisory only (settings screen). See [[Technical-Debt-Registry]] TD-006.
- Release manifest declares only `USE_BIOMETRIC`/`USE_FINGERPRINT`; **no INTERNET** (declared only in debug/profile); `allowBackup=false`; no HTTP/analytics SDK. This is the evidence base for "no telemetry".
