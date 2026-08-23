/// WalletMelt spacing and shape constants based on a 4pt grid.
///
/// All [SizedBox], [EdgeInsets], padding, and gap values throughout
/// the app must reference these constants rather than arbitrary doubles.
library;

import 'package:flutter/widgets.dart';

/// Spacing and Shape tokens.
abstract final class AppSpacing {
  AppSpacing._();

  // ── 4pt Grid Spacing Scale ────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double smMd = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ── Fixed Radius Scale: 12 / 16 / 24 / 999 ────────────────────────────────
  /// Small radius: 12.0 (chips, tags, subtle pills, small cards)
  static const double radiusSm = 12.0;

  /// Medium radius: 16.0 (buttons, inputs, list tiles)
  static const double radiusMd = 16.0;

  /// Large radius: 24.0 (cards, surfaces, bottom sheets, hero containers)
  static const double radiusLg = 24.0;

  /// Full pill / circular radius: 999.0
  static const double radiusPill = 999.0;

  // Backward-compatible semantic aliases
  static const double cardRadius = radiusLg;
  static const double sheetRadius = radiusLg;
  static const double chipRadius = radiusSm;
  static const double buttonRadius = radiusMd;

  // ── Padding Presets ────────────────────────────────────────────────────────
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingSmMd = EdgeInsets.all(smMd);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: md);

  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(lg, smMd, lg, lg);

  // ── Spatial Gaps ───────────────────────────────────────────────────────────
  static const Widget gapXs = SizedBox(height: xs, width: xs);
  static const Widget gapSm = SizedBox(height: sm, width: sm);
  static const Widget gapSmMd = SizedBox(height: smMd, width: smMd);
  static const Widget gapMd = SizedBox(height: md, width: md);
  static const Widget gapLg = SizedBox(height: lg, width: lg);
  static const Widget gapXl = SizedBox(height: xl, width: xl);
  static const Widget gapXxl = SizedBox(height: xxl, width: xxl);
}

typedef Sp = AppSpacing;
