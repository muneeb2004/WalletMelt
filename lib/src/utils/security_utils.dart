import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class SecurityUtils {
  static Future<void> enableSecureScreen() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  static Future<void> disableSecureScreen() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }
}
