---
type: adr
status: accepted
created: 2026-09-04
updated: 2026-09-13
domain: engineering
related:
  - "[[Build-and-Release-Pipeline]]"
---

# ADR-0006: Standardized Five-Target APK Build Pipeline

## Status
Accepted

## Context
WalletMelt requires distinct release packages for different distribution contexts: a universal fat APK for general distribution, split-per-ABI APKs for minimal download size on modern architectures, and a mock-seeded APK for automated screenshot generation. Running ad-hoc build commands led to mismatched builds.

## Decision
Standardize build pipeline via `AGENTS.md` and `scripts/build_apks.ps1` to produce exactly 5 artifacts on every release:
1. `app-production-release.apk` (Universal Fat APK)
2. `app-arm64-v8a-production-release.apk`
3. `app-armeabi-v7a-production-release.apk`
4. `app-x86_64-production-release.apk`
5. `app-screenshots-release.apk` (with `SCREENSHOT_MODE=true`)

## Alternatives Considered
1. **AAB (Android App Bundle) Only**: Kept for Play Store, but direct APKs are required for GitHub releases, sideloading, and testing.
2. **Build Universal Only**: Rejected because universal fat APKs (~68MB) are 3x larger than optimized architecture APKs (~22MB).

## Consequences
- **Positive**: Completely reproducible, automated, standardized releases with file sizes reported in MB.
- **Negative**: Full pipeline build time takes ~5–6 minutes.

## Related Code
- `scripts/build_apks.ps1`
- `AGENTS.md`
