import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Secure clipboard helper that clears sensitive data after a designated TTL (default: 30 seconds).
class SecureClipboardService {
  static Timer? _clearTimer;
  static String? _testClipboard;

  /// Copies [text] to the system clipboard and schedules an automatic clear after [ttl].
  static Future<void> copyWithTtl(
    String text, {
    Duration ttl = const Duration(seconds: 30),
  }) async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      _testClipboard = text;
    } else {
      await Clipboard.setData(ClipboardData(text: text));
    }

    _clearTimer?.cancel();
    _clearTimer = Timer(ttl, () async {
      if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
        if (_testClipboard == text) {
          _testClipboard = '';
        }
      } else {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == text) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      }
    });
  }

  /// Retrieves current text from clipboard.
  static Future<String?> getText() async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return _testClipboard;
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// Cancels any scheduled clear timer.
  static void cancelScheduledClear() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
