/// WalletMelt spacing and shape constants.
///
/// All [SizedBox], [EdgeInsets], padding, and gap values throughout
/// the app must reference these constants rather than raw doubles.
library;

import 'package:flutter/widgets.dart';

/// Spacing scale — based on an 8 px grid.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ── Shape radii ──────────────────────────────────────────────────────────
  /// Standard card corner radius (used by AppCard / LiquidGlass wrappers).
  static const double cardRadius = 28.0;

  /// Top-corner radius applied to bottom sheets.
  static const double sheetRadius = 20.0;

  /// Radius for category chips, filter chips, and tag chips.
  static const double chipRadius = 8.0;

  /// Primary and secondary action-button radius.
  static const double buttonRadius = 18.0;

  // ── Common EdgeInsets presets ────────────────────────────────────────────
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: md);

  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(lg, sm, lg, lg);

  // ── Standard Spatial Gaps ──────────────────────────────────────────────────
  static const Widget gapXs = SizedBox(height: xs, width: xs);
  static const Widget gapSm = SizedBox(height: sm, width: sm);
  static const Widget gapMd = SizedBox(height: md, width: md);
  static const Widget gapLg = SizedBox(height: lg, width: lg);
  static const Widget gapXl = SizedBox(height: xl, width: xl);
  static const Widget gapXxl = SizedBox(height: xxl, width: xxl);
}

/// Convenience alias so existing code that uses raw doubles can be migrated
/// call-site by call-site without a big-bang rename.
typedef Sp = AppSpacing;
