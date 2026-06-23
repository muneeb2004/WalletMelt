/// WalletMelt central tactile feedback service.
///
/// Wraps native Flutter [HapticFeedback] to provide consistent haptic
/// response profiles across screens, buttons, and custom controls.
library;

import 'package:flutter/services.dart';

abstract final class WMHaptics {
  WMHaptics._();

  /// Standard subtle click for general selections and keypads.
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// A more pronounced click for primary button presses.
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy click representing important or destructive actions.
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Soft tactile feedback for wheel scroll, tab switch, or navigation click.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// SUCCESS confirmation haptic sequence.
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
  }

  /// ERROR or Warning haptic pattern (medium impact double trigger).
  static Future<void> error() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }
}
