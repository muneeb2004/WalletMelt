import 'dart:io' as io;
import 'package:flutter/foundation.dart';

/// Cross-platform utility to safely query platform details without throwing
/// [UnsupportedError] when running on Flutter Web.
class PlatformInfo {
  const PlatformInfo._();

  static const bool isWeb = kIsWeb;

  static bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  static bool get isIOS => !kIsWeb && io.Platform.isIOS;
  static bool get isMacOS => !kIsWeb && io.Platform.isMacOS;
  static bool get isWindows => !kIsWeb && io.Platform.isWindows;
  static bool get isLinux => !kIsWeb && io.Platform.isLinux;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  static bool get isFlutterTest =>
      !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');
}
