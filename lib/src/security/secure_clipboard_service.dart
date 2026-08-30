import 'dart:async';
import 'package:flutter/services.dart';

import '../utils/platform_info.dart';

/// Secure clipboard helper that clears sensitive data after a designated TTL (default: 30 seconds).
class SecureClipboardService {
  static Timer? _clearTimer;
  static String? _testClipboard;

  /// Copies [text] to the system clipboard and schedules an automatic clear after [ttl].
  static Future<void> copyWithTtl(
    String text, {
    Duration ttl = const Duration(seconds: 30),
  }) async {
    if (PlatformInfo.isFlutterTest) {
      _testClipboard = text;
    } else {
      await Clipboard.setData(ClipboardData(text: text));
    }

    _clearTimer?.cancel();
    _clearTimer = Timer(ttl, () async {
      if (PlatformInfo.isFlutterTest) {
        if (_testClipboard == text) {
          _testClipboard = '';
        }
      } else {
        try {
          final current = await Clipboard.getData(Clipboard.kTextPlain);
          if (current?.text == text) {
            await Clipboard.setData(const ClipboardData(text: ''));
          }
        } catch (_) {}
      }
    });
  }

  /// Retrieves current text from clipboard.
  static Future<String?> getText() async {
    if (PlatformInfo.isFlutterTest) {
      return _testClipboard;
    }
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (_) {
      return null;
    }
  }

  /// Cancels any scheduled clear timer.
  static void cancelScheduledClear() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
