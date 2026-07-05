import 'dart:io';
import 'package:flutter/foundation.dart';

import '../services/platform/window_security_channel.dart';

class SecurityUtils {
  static Future<void> enableSecureScreen() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await WindowSecurityChannel.setSecureScreenEnabled(true);
    } catch (_) {}
  }

  static Future<void> disableSecureScreen() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await WindowSecurityChannel.setSecureScreenEnabled(false);
    } catch (_) {}
  }
}
