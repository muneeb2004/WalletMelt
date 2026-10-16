/// WalletMelt type scale (ADR-0010): six steps only, 34 / 22 / 17 / 14 / 12 / 11.
///
/// Add no other sizes. Nothing below [caption].
library;

import 'package:flutter/material.dart';

abstract final class WMType {
  WMType._();

  static const String family = 'PlusJakartaSans';

  static const double displaySize = 34;
  static const double headlineSize = 22;
  static const double titleSize = 17;
  static const double bodySize = 14;
  static const double labelSize = 12;
  static const double captionSize = 11;

  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle _s(double size, int weight, Color color,
          {double? height, double spacing = 0}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
        color: color,
        height: height,
        letterSpacing: spacing,
        fontFeatures: _tabular,
      );

  static TextTheme textTheme(ColorScheme scheme) {
    final on = scheme.onSurface;
    final variant = scheme.onSurfaceVariant;
    return TextTheme(
      displaySmall: _s(displaySize, 800, on, height: 1.1, spacing: -0.8),
      headlineMedium: _s(headlineSize, 800, on, height: 1.15, spacing: -0.4),
      titleLarge: _s(titleSize, 700, on, height: 1.25, spacing: -0.2),
      titleMedium: _s(bodySize, 700, on, height: 1.3),
      titleSmall: _s(bodySize, 600, on, height: 1.3),
      bodyLarge: _s(bodySize, 500, on, height: 1.4),
      bodyMedium: _s(bodySize, 500, variant, height: 1.4),
      bodySmall: _s(labelSize, 500, variant, height: 1.4),
      labelLarge: _s(bodySize, 700, on, spacing: 0.1),
      labelMedium: _s(labelSize, 600, variant, spacing: 0.1),
      labelSmall: _s(captionSize, 600, variant, spacing: 0.2),
    );
  }
}
