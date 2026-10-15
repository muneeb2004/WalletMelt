---
type: adr
status: accepted
created: 2026-08-25
updated: 2026-10-15
domain: security
related:
  - "[[Security-and-Authentication]]"
---

# ADR-0004: Fail-Closed PIN and Biometric Security Model

## Status
Accepted

## Context
Users store private financial transaction history in WalletMelt. Physical device borrowing or loss could expose this data if the application does not have a resilient authentication barrier.

## Decision
Implement a multi-layered, fail-closed security architecture:
1. 4-digit Master PIN hashed with PBKDF2-HMAC-SHA256 (corrected 2026-10-15; originally recorded as SHA-256) and unique salt in `FlutterSecureStorage`.
2. Biometric authentication as an optional convenience layer, requiring an active PIN as prerequisite.
3. Fail-closed initialization: if storage or hardware detection throws, `PinLockController` defaults to locked.
4. Strict 30-second background grace period.
5. 5-attempt failure throttle enforcing a 30-second cooldown timer.
6. `FLAG_SECURE` window protection.

## Alternatives Considered
1. **Biometrics-Only Authentication**: Rejected because biometric hardware failure or OS permission revocation would permanently lock out the user.
2. **Instant Re-Lock On Minimize**: Rejected because momentary app switching (e.g. copying a number from SMS/calculator) created severe user friction.

## Consequences
- **Positive**: High privacy protection, robust fail-closed defense, smooth UX with 30s grace window.
- **Negative**: Native platform channel dependencies (`local_auth`, `flutter_secure_storage`).

## Related Code
- `lib/src/security/pin_lock_controller.dart`
- `lib/src/security/pin_service.dart`
- `lib/src/security/biometric_service.dart`
