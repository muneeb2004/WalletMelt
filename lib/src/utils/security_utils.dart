import 'package:flutter/foundation.dart';

import '../services/platform/window_security_channel.dart';
import 'platform_info.dart';

class SecurityUtils {
  /// Compile-time constant for screenshot generation & test automation.
  /// Set via `--dart-define=SCREENSHOT_MODE=true` or `--dart-define=WALLETMELT_SCREENSHOT_MODE=true`.
  static const bool isScreenshotMode = bool.fromEnvironment(
    'SCREENSHOT_MODE',
    defaultValue: bool.fromEnvironment('WALLETMELT_SCREENSHOT_MODE', defaultValue: false),
  );

  /// Enables Android window security flag (FLAG_SECURE) to prevent unauthorized
  /// screen recording, OS recents screenshot leakage, and screen captures.
  ///
  /// SECURITY DECISION & GUARANTEES:
  /// - In release/profile builds (`kReleaseMode == true` or `kProfileMode == true`),
  ///   `FLAG_SECURE` is ALWAYS enforced, ignoring screenshot flags to ensure production security.
  /// - In debug/test environments, `FLAG_SECURE` is bypassed ONLY when
  ///   `isScreenshotMode` is true, allowing automated screenshot
  ///   pipelines to capture publication assets.
  /// - Web and non-Android platforms safely early-exit without error.
  static Future<void> enableSecureScreen() async {
    if (PlatformInfo.isWeb || !PlatformInfo.isAndroid) return;

    // Security Gate: In release or profile builds, NEVER bypass security.
    if (kReleaseMode || kProfileMode) {
      try {
        await WindowSecurityChannel.setSecureScreenEnabled(true);
      } catch (_) {}
      return;
    }

    // In controlled debug / test environments, permit screenshot bypass if screenshot mode is enabled.
    if (isScreenshotMode) {
      return;
    }

    try {
      await WindowSecurityChannel.setSecureScreenEnabled(true);
    } catch (_) {}
  }

  static Future<void> disableSecureScreen() async {
    if (PlatformInfo.isWeb || !PlatformInfo.isAndroid) return;
    try {
      await WindowSecurityChannel.setSecureScreenEnabled(false);
    } catch (_) {}
  }
}
